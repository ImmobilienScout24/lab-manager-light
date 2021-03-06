use strict;
use warnings;

use Test::More;
use Test::Warn;
use Test::Exception;
use Test::MockModule;
use LML::Common;
use LML::Config;
use LML::Result;

# load shipped configuration
my $C = new LML::Config( "src/lml/default.conf", "test/data/test.conf" );

# mock needed function from LML::VMware
use LML::VMware;
my $mock            = new Test::MockModule('LML::VMware');
my $off_value       = undef;
my $extraopts_key   = undef;
my $extraopts_value = undef;
my $VM_ALL = {
               "42130272-a509-8010-6e85-4e01cb1b7284" => {
                                                           "CUSTOMFIELDS" => {
                                                                               "Contact User ID" => "User1",
                                                                               "Expires"         => "31.12.2013"
                                                           },
                                                           "EXTRAOPTIONS" => { "bios.bootDeviceClasses" => "allow:net" },
                                                           "MAC"          => { "01:02:03:04:00:15"      => "arc.int" },
                                                           "NAME"         => "lochst001",
                                                           "HOST"         => "testesx01.domain",
                                                           "NETWORKING"   => [ {
                                                                               "MAC"     => "01:02:03:04:00:15",
                                                                               "NETWORK" => "arc.int"
                                                                             }
                                                           ],
                                                           "PATH"  => "development/vm/path/lochst001",
                                                           "VM_ID" => "vm-0500",
                                                           "UUID"  => "42130272-a509-8010-6e85-4e01cb1b7284"
               },
               "4213038e-9203-3a2b-ce9d-c6dac1f2dbbf" => {
                                                           "CUSTOMFIELDS" => {
                                                                               "Contact User ID" => "User2",
                                                                               "Expires"         => "31.01.2013",
                                                                               "Force Boot"      => ""
                                                           },
                                                           "EXTRAOPTIONS" => { "bios.bootDeviceClasses" => "allow:net" },
                                                           "MAC"          => {
                                                                      "01:02:03:04:6e:4e" => "arc.int",
                                                                      "01:02:03:04:9e:9e" => "foo"
                                                           },
                                                           "NAME"       => "tsthst001",
                                                           "HOST"       => "testesx01.domain",
                                                           "NETWORKING" => [ {
                                                                               "MAC"     => "01:02:03:04:6e:4e",
                                                                               "NETWORK" => "arc.int"
                                                                             },
                                                                             {
                                                                               "MAC"     => "01:02:03:04:9e:9e",
                                                                               "NETWORK" => "foo"
                                                                             }
                                                           ],
                                                           "PATH"  => "development/vm/otherpath/tsthst001",
                                                           "VM_ID" => "vm-1000",
                                                           "UUID"  => "4213038e-9203-3a2b-ce9d-c6dac1f2dbbf"
               },
               "4213038e-9203-3a2b-ce9d-123456789abc" => {
                                                           "CUSTOMFIELDS" => {
                                                                               "Contact User ID"   => "User3",
                                                                               "Expires"           => "31.01.2010",
                                                                               "Force Boot"        => "garbage",
                                                                               "Force Boot Target" => "server"
                                                           },
                                                           "EXTRAOPTIONS" => { "bios.bootDeviceClasses" => "allow:net" },
                                                           "MAC"          => { "01:02:03:04:6e:5c"      => "arc.int" },
                                                           "NAME"         => "tsthst099",
                                                           "HOST"         => "testesx01.domain",
                                                           "NETWORKING"   => [ {
                                                                               "MAC"     => "01:02:03:04:6e:5c",
                                                                               "NETWORK" => "arc.int"
                                                                             }
                                                           ],
                                                           "PATH"  => "development/vm/otherpath/tsthst099",
                                                           "VM_ID" => "vm-2000",
                                                           "UUID"  => "4213038e-9203-3a2b-ce9d-123456789abc"
               },
               "4213c435-a176-a533-e07e-38644cf43390" => {
                                                           "CUSTOMFIELDS" => {
                                                                               "Contact User ID" => "unrelated1",
                                                                               "Expires"         => "01.01.2015"
                                                           },
                                                           "MAC"        => { "01:02:03:04:2e:73" => "vlan_902" },
                                                           "NAME"       => "Some VM123",
                                                           "HOST"       => "testesx01.domain",
                                                           "NETWORKING" => [ {
                                                                               "MAC"     => "01:02:03:04:2e:73",
                                                                               "NETWORK" => "vlan_123"
                                                                             }
                                                           ],
                                                           "PATH"  => "development/vm/Unrelated/VMPath/Web-Java/Some VM123",
                                                           "UUID"  => "4213c435-a176-a533-e07e-38644cf43390",
                                                           "VM_ID" => "vm-9876"
               } };

$mock->mock(
    'get_vm_data',
    sub {
        my $uuid = shift;
        #diag("Mock get_vm_data($uuid):\n");
        return \() unless ( exists $VM_ALL->{$uuid} );
        return $VM_ALL->{$uuid};

    } );

$mock->mock(
    'setVmCustomValue',
    sub {
        my $uuid            = shift;
        my $forceboot_field = shift;
        $off_value = shift;

        #diag("Mock setVmCustomValue($uuid,$forceboot_field,$off_value)\n");
        return 1;
    } );

$mock->mock(
    'setVmExtraOptsU',
    sub {
        my $uuid;
        ( $uuid, $extraopts_key, $extraopts_value ) = @_;
        #diag("Mock setVmExtraOptsU($uuid,$extraopts_key,$extraopts_value)\n");
        return 1;
    } );
use_ok "LML::VM";

use_ok "LML::Lab";

use_ok "LML::VMpolicy";

my $Pgood = new LML::VMpolicy( $C, new LML::VM("4213038e-9203-3a2b-ce9d-c6dac1f2dbbf") );
my $Pbad  = new LML::VMpolicy( $C, new LML::VM("4213c435-a176-a533-e07e-38644cf43390") );

#### validate_vm_name
#
#
is( $Pgood->validate_vm_name, undef, "should return undef for correct VM name" );
is( $Pbad->validate_vm_name, "VM name may only contain a-z0-9_- characters", "should return error message for invalid VM name" );

#### validate_hostrules_pattern
#
#
is( $Pgood->validate_hostrules_pattern, undef, "should return undef for matching VM name" );
is(
    $Pbad->validate_hostrules_pattern,
    "VM name does not match '^[a-z]{6}[0-9]{3}\$' pattern",
    "should return error message for non-matching VM name"
);

#### validate_contact_user
#
#
is_deeply( [ $Pgood->validate_contact_user ], ["Contact User ID 'User2' does not exist"], "should return error about non-existant user" );
is_deeply( [
              new LML::VMpolicy(
                                 new LML::Config( {
                                                    "vsphere" => {
                                                                   "contactuserid_field"  => "ci_field",
                                                                   "contactuserid_minuid" => "0",
                                                    } }
                                 ),
                                 new LML::VM( { "CUSTOMFIELDS" => { "ci_field" => "root" } } )
                )->validate_contact_user
           ],
           [],
           "should not return any error as root user always exists"
);
is_deeply( [
              new LML::VMpolicy(
                                 new LML::Config( {
                                                    "vsphere" => {
                                                                   "contactuserid_field"  => "ci_field",
                                                                   "contactuserid_minuid" => "9999",
                                                    } }
                                 ),
                                 new LML::VM( { "CUSTOMFIELDS" => { "ci_field" => "root" } } )
                )->validate_contact_user
           ],
           ["ci_field 'root' is not allowed"],
           "should return error that user root is not allowed"
);
is_deeply( [
              new LML::VMpolicy(
                                 new LML::Config( {
                                                    "vsphere" => {
                                                                   "contactuserid_field"  => "ci_field",
                                                                   "contactuserid_minuid" => "9999",
                                                    } }
                                 ),
                                 new LML::VM( { "CUSTOMFIELDS" => { "ci_field" => "" } } )
                )->validate_contact_user
           ],
           ["ci_field '' does not exist"],
           "should return error that empty user does not exist"
);
is_deeply( [
              new LML::VMpolicy(
                                 new LML::Config( {
                                                    "vsphere" => {
                                                                   "contactuserid_field"  => "ci_field",
                                                                   "contactuserid_minuid" => "9999",
                                                    } }
                                 ),
                                 new LML::VM( { "CUSTOMFIELDS" => { "ci_field" => "invalid user" } } )
                )->validate_contact_user
           ],
           ["ci_field 'invalid user' does not exist"],
           "should return error that empty user does not exist"
);

######### handle_forceboot
#
#

# Prepare the test
my $VM     = new LML::VM("4213038e-9203-3a2b-ce9d-123456789abc");
my $result = new LML::Result($C);
my $Policy = new LML::VMpolicy( $C, $VM );
$Policy->handle_forceboot($result);

# test the values in result, which were set via handle_forceboot from VMpolicy.pm
is( $result->{redirect_target}, "menu/server.sl6.txt",        "should redirect to menu/server.sl6.txt" );
is( $result->{statusinfo},      "force boot from LML config", "should be 'force boot from LML config'" );

# test if error handling is working
$VM->{"CUSTOMFIELDS"}->{"Force Boot Target"} = "foobar";
$Policy->handle_forceboot($result);
is_deeply( $result->get_errors,
           "Invalid force boot target in 'Force Boot Target'",
           "Should fail with 'Invalid force boot target in 'Force Boot Target''" );

# test for intended fatal error
dies_ok {
    ( new LML::VMpolicy( $C, new LML::VM( { "CUSTOMFIELDS" => { "Force Boot" => "ON", "Force Boot Target" => "fatalerror" } } ) ) )
      ->handle_forceboot($result);
}
"should die if fatalerror requested";

# test for unmanaged
dies_ok {
    ( new LML::VMpolicy( $C, new LML::VM( { "CUSTOMFIELDS" => { "Force Boot" => "unmanaged" } } ) ) )->handle_unmanaged($result);
}
"should die for unmanaged VM via Force Boot";
dies_ok {
    ( new LML::VMpolicy( $C, new LML::VM( { "CUSTOMFIELDS" => { "Force Boot Target" => "unmanaged" } } ) ) )->handle_unmanaged($result);
}
"should die for unmanaged VM via Force Boot Target";
done_testing();
