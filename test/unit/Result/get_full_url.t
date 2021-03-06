use strict;
use warnings;

use Test::More;

use LML::Config;
use LML::Common;

BEGIN {
    use_ok "LML::Result";
}


my $result = new_ok( "LML::Result" => [ new LML::Config( {} ), "http://foo.bar/boot/pxelinux.cfg/12345-123-123" ] );
is ($result->get_full_url(),"","should return empty if no argument given");
is ($result->get_full_url("script.pl"),"http://foo.bar/boot/script.pl","yield full url stripped of pxelinux.cfg/*");
is ($result->get_full_url("/some/thing"),"http://foo.bar/some/thing","yield full url outside of LML");
is ($result->get_full_url("http://other.domain/page"),"http://other.domain/page","yield url on other host");
done_testing();
