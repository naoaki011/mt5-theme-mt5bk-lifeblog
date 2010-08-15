#
# SortCatFld.pl
# 2007/08/26 1.00 For Movable Type 4
# 2007/09/07 1.01 Bug fix
# 2008/01/25 1.02 For Movable Type 4.1 / MTOS
# 2009/09/24 1.10 For Movable Type 5
#
# Copyright(c) by H.Fujimoto
#
package MT::Plugin::SortCatFld;
use base 'MT::Plugin';

use strict;

use MT;
use MT::Plugin;
use MT::Category;
use MT::Folder;
use MT::Blog;
use MT::Website;
use MT::Request;

my $plugin = MT::Plugin::SortCatFld->new({
    name => 'Sort Categories And Folders',
    version => '1.10',
    author_name => '<__trans phrase="Hajime Fujimoto">',
    author_link => 'http://www.h-fj.com/blog/',
    doc_link => 'http://www.h-fj.com/blog/mt5plgdoc/sortcatfld.php',
    description => '<__trans phrase="Sort categories and folders as you like.">',
    blog_config_template => \&blog_config,
    schema_version => '1.01',
    l10n_class => 'SortCatFld::L10N',
});

MT->add_plugin($plugin);

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        object_types => {
            'category' => {
                'order_number' => 'integer',
            },
        },
        callbacks => {
            'MT::App::CMS::template_param.list_category'
                => \&sort_categories_catlist,
            'MT::App::CMS::template_param.list_folder'
                => \&sort_categories_catlist,
            'MT::App::CMS::template_param.edit_entry'
                => \&sort_categories_entry,
            'MT::App::CMS::template_param.asset_upload'
                => \&sort_categories_entry,
            'MT::App::CMS::template_param.asset_list'
                => \&sort_categories_entry,
            'MT::Category::pre_save' => {
                priority => 1,
                code => \&category_pre_save,
            },
            'MT::Folder::pre_save' => {
                priority => 1,
                code => \&folder_pre_save,
            },
        },
        applications => {
            'cms' => {
                'methods' => {
                    'sort_cat_setting' => \&sort_categories_setting,
                    'sort_fld_setting' => \&sort_categories_setting,
                    'sort_cat_save' => \&sort_categories_save,
                    'sort_fld_save' => \&sort_categories_save,
                },
                'menus' => {
                    'entry:sort_category' => {
                        label      => "Sort categories",
                        order      => 350,
                        mode       => 'sort_cat_setting',
                        permission => 'edit_categories',
                        view       => 'blog',
                        condition  => sub {
                            my $app = MT->instance;
                            my $blog_id = $app->param('blog_id') or return 0;
#                            my @cats = MT::Category->load({ blog_id => $blog_id });
#                            return scalar(@cats);
                            return 1;
                        },
                    },
                    'page:sort_folder' => {
                        label      => "Sort folders",
                        order      => 350,
                        mode       => 'sort_fld_setting',
                        permission => 'manage_pages',
                        view       => [ 'blog', 'website' ],
                        condition  => sub {
                            my $app = MT->instance;
                            my $blog_id = $app->param('blog_id') or return 0;
#                            my @flds = MT::Folder->load({ blog_id => $blog_id });
#                            return scalar(@flds);
                            return 1;
                        },
                    },
                },
            },
        },
        upgrade_functions => {
            'init_order_number' => {
                version_limit => '1.01',
                code => \&init_order_number
            },
        },
        tags => {
            block => {
                'SortedTopLevelCategories' => \&sorted_top_level_categories,
                'SortedSubCategories' => \&sorted_sub_categories,
                'SortedTopLevelFolders' => \&sorted_top_level_folders,
                'SortedSubFolders' => \&sorted_sub_folders,
                'SortedEntryCategories' => \&sorted_entry_categories,
                'SortedCategoryPrevious' => \&sorted_category_prev_next,
                'SortedCategoryNext' => \&sorted_category_prev_next,
                'SortedFolderPrevious' => \&sorted_folder_prev_next,
                'SortedFolderNext' => \&sorted_folder_prev_next,
            },
        }
    });
}

sub init_order_number {
    my $app = MT->instance;
    my $blog_class = $app->model('blog');
    my $cat_class = $app->model('category');
    my $fld_class = $app->model('folder');

    my @blogs = $blog_class->load;
    for my $blog (@blogs) {
        my $counter = 1;
        my @cats = $cat_class->load(
            { blog_id => $blog->id },
            { sort => 'label', direction => 'ascend' },
        );
        for my $cat (@cats) {
            $counter++ if ($cat->order_number);
        }
        for my $cat (@cats) {
            unless ($cat->order_number) {
                $cat->order_number($counter);
                $cat->save;
                $counter++;
            }
        }
        $counter = 1;
        my @flds = $fld_class->load(
            { blog_id => $blog->id },
            { sort => 'label', direction => 'ascend' },
        );
        for my $fld (@flds) {
            $counter++ if ($fld->order_number);
        }
        for my $fld (@flds) {
            unless ($fld->order_number) {
                $fld->order_number($counter);
                $fld->save;
                $counter++;
            }
        }
    }
}

sub sort_categories_entry {
    my ($cb, $app, $param, $tmpl) = @_;

    my $cats = $param->{category_tree};
    my $cat_count = scalar @$cats;
    my $type = ($app->mode eq 'sort_cat_setting' ||
                $app->mode eq 'start_upload' ||
                $app->mode eq 'list_asset')
        ? 'category' : 'folder';
    my $obj_class = $app->model($type);

    for (my $i = 0; $i < $cat_count; $i++) {
        my $cat_id = $cats->[$i]->{id};
        $cats->[$i]->{category_id} = $cat_id;
        if ($cat_id == -1) {
            $cats->[$i]->{category_order_number} = -1;
        }
        else {
            my $cat = $obj_class->load($cat_id);
            $cats->[$i]->{category_order_number} = $cat->order_number;
        }
    }
    &_sort_categories($app, $cats);
}

sub sort_categories_catlist {
    my ($cb, $app, $param, $tmpl) = @_;
    my ($msg, $mode);

    my $cats = $param->{category_loop};
    &_sort_categories($app, $cats);
}

sub _sort_categories {
    my $app = shift;
    my $cats = shift;

    my $cat_count = scalar @$cats;
    my $no_ordered_no = $cat_count + 1;

    my $type = ($app->mode eq 'sort_cat_setting')
        ? 'category' : 'folder';
    my $obj_class = $app->model($type);

    # create category tree
    my $cat_tree = {};
    my $cat_id;
    my $root_flag = 0;
    for (my $i = 0; $i < $cat_count; $i++) {
        $cat_id = $cats->[$i]->{category_id};
        my ($cat, @parent_cats);
        if ($cat_id > 0) {
            $cat = $obj_class->load($cat_id);
            if (defined($cat->order_number)) {
                $cats->[$i]->{category_order_number} = $cat->order_number;
            }
            else {
                $cats->[$i]->{category_order_number} = $no_ordered_no;
                $no_ordered_no++;
            }
            @parent_cats = $cat->parent_categories;
        }
        elsif ($cat_id == -1) {
            $cats->[$i]->{category_order_number} = -1;
            $root_flag = 1;
            @parent_cats = ();
        }
        if ($type eq 'folder' && $cat_id != -1 && $root_flag) {
            my $tmp_cat = $obj_class->new;
            $tmp_cat->id(-1);
            push @parent_cats, $tmp_cat;
        }
        @parent_cats = reverse @parent_cats;
        my $tmp_tree = $cat_tree;
        for my $parent_cat (@parent_cats) {
            unless(defined($tmp_tree->{$parent_cat->id})) {
                $tmp_tree->{$parent_cat->id} = {};
            }
            $tmp_tree = $tmp_tree->{$parent_cat->id};
       }
       $tmp_tree->{$cat_id} = { 
          cattree_index => $i,
          order_number => $cats->[$i]->{category_order_number},
          label => $cats->[$i]->{category_label},
       };
    }

    &_sort_cat_tree($cats, $cat_tree);
    @$cats = sort { $a->{category_order_number} <=>
                    $b->{category_order_number} } @$cats;
}

{
    my $order_no = 1;

    sub _sort_cat_tree {
        my $cats = shift;
        my $cat_tree = shift;

        my @cat_ids = keys %$cat_tree;
        @cat_ids = grep { $_ =~ /\d+/ } @cat_ids;
        return if (!@cat_ids);

        @cat_ids = sort { $cat_tree->{$a}->{order_number} <=> 
                          $cat_tree->{$b}->{order_number} } @cat_ids;

        for my $cat_id (@cat_ids) {
            $cat_tree->{$cat_id}->{order_number} = $order_no;
            my $cats_index = $cat_tree->{$cat_id}->{cattree_index};
            $cats->[$cats_index]->{category_order_number} = $order_no;
            $order_no++;
            &_sort_cat_tree($cats, $cat_tree->{$cat_id});
        }


    }
}

sub sort_categories_setting {
    my $app = shift;
    my %param;

    my $html = '';
    my $type = ($app->mode eq 'sort_cat_setting')
        ? 'category' : 'folder';
    my $obj_class = $app->model($type);

    &_build_category_tree($app, $obj_class, 0, 0, \$html);

    $param{sort_html} = $html;
    $param{script_url} = $app->{script_url};
    my $blog_id = $app->param('blog_id');
    if (ref $blog_id eq 'ARRAY') {
        $blog_id = $blog_id->[0];
    }
    $param{blog_id} = $blog_id;
    my $blog = MT::Blog->load({ id => $blog_id,
                                class => [ 'blog', 'website' ] });
    $param{blog_label} = $blog->class_label;
    $param{saved} = $app->param('saved');
    $param{next_mode} = ($app->mode eq 'sort_cat_setting')
        ? 'sort_cat_save' : 'sort_fld_save';
    $param{sort_obj} = ($app->mode eq 'sort_cat_setting')
        ? 'category' : 'folder';
    $param{folder_mode} = ($app->mode eq 'sort_cat_setting')
        ? 0 : 1;
    $param{sort_obj} = $plugin->translate($param{sort_obj});
    $param{not_found} = $plugin->translate(
                            ($app->mode eq 'sort_cat_setting')
                            ? 'Not found categories' : 'Not found folders');
    my $tmpl = $plugin->load_tmpl('sort_categories.tmpl');
    $tmpl->text($plugin->translate_templatized($tmpl->text));
    return $app->build_page($tmpl, \%param);
}

sub _build_category_tree {
    my ($app, $obj_class, $parent, $level, $html) = @_;

    my $blog_id = $app->param('blog_id');

    my @cats = $obj_class->load({ blog_id => $blog_id, parent => $parent },
                                { sort => 'label', direction => 'ascend' });
    @cats = sort { $a->order_number <=> $b->order_number } @cats;
    my $cat_count = scalar(@cats);
    return if (!$cat_count);

    my $order_no = 1;
    my $no_order_no = $cat_count + 1;
    for (my $i = 0; $i < $cat_count; $i++) {
        if (defined($cats[$i]->order_number)) {
            $cats[$i]->order_number($order_no);
            $order_no++;
        }
        else {
            $cats[$i]->order_number($no_order_no);
            $no_order_no++;
        }

    }
    @cats = sort { $a->order_number <=> $b->order_number } @cats;

    my $sp1 = '';
    $sp1 = '  ' x ($level + 1);
    my $btn_path = $app->static_path . "plugins/SortCatFld/images/";
    my $up_phrase = $plugin->translate('Up');
    my $down_phrase = $plugin->translate('Down');
    my $top_phrase = $plugin->translate('Top');
    my $bottom_phrase = $plugin->translate('Bottom');
    $$html .="${sp1}<ul";
    if ($level == 0) {
        $$html .= " id=\"category_root\"";
    }
    $$html .= ">\n";
    for (my $i = 0; $i < $cat_count; $i++) {
        my $cat = $cats[$i];
        my $class = ($i != $cat_count - 1) ? '' : ' class="tree_end"';
        my $up_id = 'cat' . $cat->id . 'u';
        my $down_id = 'cat' . $cat->id . 'd';
        my $top_id = 'cat' . $cat->id . 't';
        my $bottom_id = 'cat' . $cat->id . 'b';
        my $up_img = ($i) ? 'up.gif' : 'up_d.gif';
        my $down_img = ($i != $cat_count - 1) ? 'down.gif' : 'down_d.gif';
        my $top_img = ($i) ? 'top.gif' : 'top_d.gif';
        my $bottom_img = ($i != $cat_count - 1) ? 'bottom.gif' : 'bottom_d.gif';        my $up_onclick = ($i) ? ' onclick="return sort_category(this, \'up\');"' : '';
        my $down_onclick = ($i != $cat_count - 1) ? ' onclick="return sort_category(this, \'down\');"' : '';
        my $top_onclick = ($i) ? ' onclick="return sort_category(this, \'top\');"' : '';
        my $bottom_onclick = ($i != $cat_count - 1) ? ' onclick="return sort_category(this, \'bottom\');"' : '';
        my $icon_class_u = ($i) ? 'sort-icon' : 'sort-icon-d';
        my $icon_class_d = ($i != $cat_count - 1) ? 'sort-icon' : 'sort-icon-d';

        $$html .= "${sp1}<li${class} id=\"cat" . $cat->id . "\">";
        $$html .= "<img src=\"${btn_path}${top_img}\" id=\"${top_id}\" width=\"10\" height=\"10\"${top_onclick} alt=\"${top_phrase}\" title=\"${top_phrase}\" class=\"${icon_class_u}\" />";
        $$html .= "<img src=\"${btn_path}${up_img}\" id=\"${up_id}\" width=\"10\" height=\"10\"${up_onclick} alt=\"${up_phrase}\" title=\"${up_phrase}\" class=\"${icon_class_u}\" />";
        $$html .= "<img src=\"${btn_path}${down_img}\" id=\"${down_id}\" width=\"10\" height=\"10\"${down_onclick} alt=\"${down_phrase}\" title=\"${down_phrase}\" class=\"${icon_class_d}\" />";
        $$html .= "<img src=\"${btn_path}${bottom_img}\" id=\"${bottom_id}\" width=\"10\" height=\"10\"${bottom_onclick} alt=\"${bottom_phrase}\" title=\"${bottom_phrase}\" class=\"${icon_class_d}\" />";
        $$html .= $cat->label . "\n";
        &_build_category_tree($app, $obj_class, $cat->id, $level + 1, $html);
        $$html .= "$sp1</li>\n";
    }
    $$html .="$sp1</ul>\n";
}

sub sort_categories_save {
    my $app = shift;

    my $type = ($app->mode eq 'sort_cat_save')
        ? 'category' : 'folder';
    my $obj_class = $app->model($type);

    my @params = $app->param;
    for my $param (@params) {
        if ($param =~ /cat(\d+)/) {
            my $cat_id = $1;
            my $order_number = $app->param('cat' . $cat_id);
            my $cat = $obj_class->load($cat_id);
            $cat->order_number($order_number);
            $cat->save
                or return $app->error($plugin->translate('Save category error'));
        }
    }

    my $mode = ($app->mode eq 'sort_cat_save')
             ? 'sort_cat_setting' : 'sort_fld_setting';
    $app->redirect(
        $app->uri(mode => $mode,
                  args => { blog_id => $app->param('blog_id'),
                            saved => 1 }));
}

sub category_pre_save {
    my ($eh, $cat) = @_;

    unless (defined($cat->order_number)) {
        my @cats = MT::Category->load({ blog_id => $cat->blog_id });
        my $max = 0;
        map { $max = $_->order_number if ($max < $_->order_number) } @cats;
        $cat->order_number($max + 1);
    }
}

sub folder_pre_save {
    my ($eh, $fld) = @_;

    unless (defined($fld->order_number)) {
        my @flds = MT::Folder->load({ blog_id => $fld->blog_id });
        my $max = 0;
        map { $max = $_->order_number if ($max < $_->order_number) } @flds;
        $fld->order_number($max + 1);
    }
}

# MTSortedTopLevelCategories tag
sub sorted_top_level_categories {
    my ($ctx, $args, $cond) = @_;

    $args->{sort_method} = 'SortCatFld::Sort';
    return $ctx->tag('TopLevelCategories', $args, $cond);
}

# MTSortedSubCategories tag
sub sorted_sub_categories {
    my ($ctx, $args, $cond) = @_;

    $args->{sort_method} = 'SortCatFld::Sort';
    return $ctx->tag('SubCategories', $args, $cond);
}

# MTSortedTopLevelFolders tag
sub sorted_top_level_folders {
    my ($ctx, $args, $cond) = @_;

    $args->{sort_method} = 'SortCatFld::Sort';
    return $ctx->tag('TopLevelFolders', $args, $cond);
}

# MTSortedSubFolders tag
sub sorted_sub_folders {
    my ($ctx, $args, $cond) = @_;

    $args->{sort_method} = 'SortCatFld::Sort';
    return $ctx->tag('SubFolders', $args, $cond);
}

# MTSortedEntryCategories tag
sub sorted_entry_categories {
    my ($ctx, $args, $cond) = @_;

    my $entry = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    my $cats = $entry->categories;
    return '' if (!$cats);

    # load sorted categories
    my $req = MT::Request->instance;
    my $sorted_cats = $req->stash('SortCatFld::SortedCats');
    unless(defined($sorted_cats)) {
        $sorted_cats = {};
        my $order = 1;
        my $blog_id = $ctx->stash('blog_id');
        &_load_sorted_categories($sorted_cats, $blog_id, 0, \$order);
        $req->stash('SortCatFld::SortedCats', $sorted_cats);
    }
    # sort and grep categories
    my $pri_cat = $entry->category;
    if ($args->{exclude_primary} || $args->{primary_first} || $args->{primary_last}) {
        @$cats = grep { $_->id != $pri_cat->id } @$cats;
    }
    @$cats = sort { $sorted_cats->{$a->id}->{order} <=>
                    $sorted_cats->{$b->id}->{order} } @$cats;
    if ($args->{primary_first} && !$args->{exclude_primary} && $pri_cat) {
        unshift @$cats, $pri_cat;
    }
    elsif ($args->{primary_last} && !$args->{exclude_primary} && $pri_cat) {
        push @$cats, $pri_cat;
    }

    # out
    my $tokens = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my @res = ();
    my $entry_class = MT->model('entry');
    my $glue = $args->{glue} || '';
    my $vars = $ctx->{__stash}{vars} ||= {};
    local $vars->{__size__} = scalar(@$cats);
    my $i = 0;

    for my $cat (@$cats) {
        local $ctx->{inside_mt_categories} = 1;
        local $ctx->{__stash}->{category} = $cat;
        local $vars->{__primary__} = ($cat->id == $pri_cat->id);
        local $vars->{__order__} = $sorted_cats->{$cat->id}->{order};
        local $vars->{__first__} = !$i;
        local $vars->{__last__} = !defined $cats->[$i + 1];
        local $vars->{__odd__} = ($i % 2) == 0;
        local $vars->{__even__} = ($i % 2) == 1;
        local $vars->{__counter__} = $i + 1;
        defined(my $out = $builder->build($ctx, $tokens, $cond))
            or return $ctx->error($builder->errstr);
        push @res, $out;
        $i++;
    }
    join $glue, @res;
}

sub _load_sorted_categories {
    my ($sorted_cats, $blog_id, $parent, $order) = @_;

    my $class = MT->model('category');
    my @cats = $class->load({ blog_id => $blog_id,
                              parent => $parent },
                            { sort => 'order_number',
                              direction => 'ascend' });
    for my $cat (@cats) {
        $sorted_cats->{$cat->id} = { label => $cat->label, order => $$order };
        $$order++;
        &_load_sorted_categories($sorted_cats, $blog_id, $cat->id, $order);
    }
}

# MTSortedCategoryPrevious tag
# MTSortedCategoryNext tag
sub sorted_category_prev_next {
    my ($ctx, $args, $cond) = @_;

    my $res = '';
    my $cat = $ctx->stash('category') || $ctx->stash('archive_category');
    if ($cat) {
        # initialize
        my $tag = lc $ctx->stash('tag');
        my $direction = ($tag =~ /sorted(category|folder)previous/)
                        ? 'descend' : 'ascend';
        my $class = MT->model($cat->class);
        my $order_number = $cat->order_number;
        my $adj_cat;
        my $now_cat = $cat;
        while () {
            # load adjacent category
            my $range = ($direction eq 'descend')
                        ? [ 0, $order_number ]
                        : [ $order_number, undef ];
            $adj_cat = $class->load({ blog_id => $cat->blog_id,
                                      parent => $cat->parent,
                                      order_number => $range },
                                    { sort => 'order_number',
                                      direction => $direction,
                                      range => { order_number => 1 },
                                      limit => 1 });

            # last if no adjacent category
            last if (!$adj_cat);
            # last if no_skip argument
            last if ($args->{no_skip});
            # last if entry count of category is not zero
            my @args = ({ blog_id => $ctx->stash('blog_id'),
                          status => MT::Entry::RELEASE() },
                        { 'join' => [ 'MT::Placement', 'entry_id',
                                      { category_id => $adj_cat->id } ] });
            my $entry_class = MT->model(($cat->class eq 'category') ? 'entry' : 'page');
            my $count = scalar $entry_class->count(@args);
            last if ($count);
            # search next adjacent category
            $order_number = $adj_cat->order_number;
            $now_cat = $adj_cat;
        }
        if ($adj_cat) {
            # out category
            my $tok = $ctx->stash('tokens');
            my $builder = $ctx->stash('builder');
            local $ctx->{__stash}->{category} = $adj_cat;
            my $out = $builder->build($ctx, $tok, $cond);
            return $ctx->error($builder->errstr) unless defined $out;
            $res .= $out;
        }
    }
    return $res;
}

# MTSortedFolderPrevious tag
# MTSortedFolderNext tag
sub sorted_folder_prev_next {
    my ($ctx, $args, $cond) = @_;
    return undef unless MT::Template::Tags::Folder::_check_folder($ctx, $args, $cond);
    &sorted_category_prev_next(@_);
}

sub blog_config {
    my $blog = MT->instance->blog;
    my $blog_id = $blog->id;
    my $tmpl;
    if ($blog->is_blog) {
        $tmpl = <<HERE;
<p>
<a href="<mt:var name="mt_url">?__mode=sort_cat_setting&amp;blog_id=${blog_id}"><__trans phrase="Sort categories"></a><br />
<a href="<mt:var name="mt_url">?__mode=sort_fld_setting&amp;blog_id=${blog_id}"><__trans phrase="Sort folders"></a>
</p>
HERE
    }
    else {
        $tmpl = <<HERE;
<p>
<a href="<mt:var name="mt_url">?__mode=sort_fld_setting&amp;blog_id=${blog_id}"><__trans phrase="Sort folders"></a>
</p>
HERE
    }
    $tmpl;
}

1;
