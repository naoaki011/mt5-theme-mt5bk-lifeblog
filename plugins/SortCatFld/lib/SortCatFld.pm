package SortCatFld;
use strict;

sub Sort
{
    $MT::Template::Tags::Category::a->order_number <=>
    $MT::Template::Tags::Category::b->order_number;
}

1;
