############## OO Interface #############
#
# create a VM object which encapsulates a single VM

package LML::VM;

use strict;
use warnings;

use LML::Config;
use LML::VMware;
use LML::Common;
use Data::Dumper;;
use Carp;
use Clone 'clone';
use Array::Compare;

# new object, takes uuid
sub new {
    my $class = shift;
    my $self;
    my $search_vm = shift;
    confess("cannot use LML::VM as argument, it was\n".Data::Dumper->Dump([$search_vm])) if (ref($search_vm) eq "LML::VM");
    if ( ref($search_vm) eq "HASH" ) {
        # hashref given, turn it into a VM object.
        # if some of the data structures are missing, then you are on your own!
        $self = clone($search_vm);
        # migrate old LAB structure to new VM structure
        if ( !exists $self->{NAME} and exists $self->{HOSTNAME} ) {
            $self->{NAME} = $self->{HOSTNAME};
        }
    } else {

        unless ($search_vm) {
            carp( "Give the VM uuid or name as arg to the constructor in " . ( caller 0 )[3] );
            return undef;
        }
        # call get_vm_data with full package name so that Test::MockModule will work
        $self = LML::VMware::get_vm_data($search_vm);
        if ( not ref($self) eq "HASH" ) {
            Debug("Could not load any data for uuid '$search_vm'");
            return undef;
        }
        $self->{filter_networks} = [];
        $self->{dns_domain} = undef;
    }
    bless $self, $class;
    return $self;
}

sub _vm_view_or_uuid {
    my ($self) = @_;
    return $self->vm_view ? $self->vm_view : $self->uuid;
}

sub uuid {
    my $self = shift;
    return undef unless ( exists $self->{"UUID"} );
    return $self->{"UUID"};
}

sub name {
    my $self = shift;
    return undef unless ( exists $self->{"NAME"} );
    return $self->{"NAME"};
}

sub vm_id {
    my $self = shift;
    return undef unless ( exists $self->{"VM_ID"} );
    return $self->{"VM_ID"};
}

sub vm_view {
    my $self = shift;
    return undef unless ( exists $self->{"OBJECT"} );
    return $self->{"OBJECT"};
}

sub networks {
    # return list of network labels. First one is most likely the PXE boot network
    my $self = shift;
    my @result = map { $_->{"NETWORK"} } @{ $self->{"NETWORKING"} };
    if ( scalar(@result) == 0 ) {
        confess( "VM " . $self->uuid . " has no NETWORKING data, please check how LML could feel responsible for this VM\n" );
    }
    return @result;
}

sub matching_networks {
    # returns the networks from the list given that this VM is attached to.
    # Networks can be names or regex patterns
    my ( $self, @networks ) = @_;
    return grep {
        my $vm_network = $_;
        grep { $vm_network =~ qr(^$_$) } @networks
    } $self->networks();
}

sub mac {
    my $self = shift;
    return undef unless ( exists $self->{"MAC"} );
    return $self->{"MAC"};
}

sub path {
    my $self = shift;
    return undef unless ( exists $self->{"PATH"} );
    return $self->{"PATH"};
}

sub host {
    my $self = shift;
    return undef unless ( exists $self->{"HOST"} );
    return $self->{"HOST"};
}

sub customfields {
    my $self = shift;
    return undef unless ( exists $self->{"CUSTOMFIELDS"} );
    return $self->{"CUSTOMFIELDS"};
}

sub bootorder {
    my $self = shift;
    return undef unless (exists $self->{"BOOTORDER"} );
    return $self->{"BOOTORDER"};
}

sub get_macs {
    my $self = shift;
    return undef unless ( exists $self->{"MAC"} and ref( $self->{"MAC"} ) eq "HASH" );
    return keys %{ $self->{"MAC"} };
}

sub set_networks_filter {
    my ( $self, @filter_networks ) = @_;
    croak( "Give a list of networks to set filter in " . ( caller 0 )[3] ) unless (@filter_networks);
    Debug( 'setting networks filter ^' . join( '$, ^', @filter_networks ) . '$' );
    $self->{filter_networks} = \@filter_networks;
}

sub get_filtered_macs {
    my $self            = shift;
    my @filter_networks = @{ $self->{filter_networks} };
    return $self->get_macs unless ( scalar @filter_networks );    #return filtered macs, no filter set means return all
    my @matching_macs;
    for my $mac ( $self->get_macs ) {
        if ( grep { $self->{"MAC"}->{$mac} =~ qr(^$_$) } @filter_networks ) {
            push @matching_macs, $mac;
        }
    }
    Debug("get_filtered_macs(".$self->name.")=".join(", ",@matching_macs));
    return @matching_macs if (wantarray);
    return scalar @matching_macs;
}

sub set_dns_domain {
    my ($self,$new_dns_domain) = @_;
    $self->{dns_domain} = $new_dns_domain;
}

sub dns_domain {
    my $self = shift;
    return exists($self->{dns_domain}) ? $self->{dns_domain} : undef;
}

sub forcenetboot {
    my $self = shift;
    my $result = 0;
    if (exists $self->{EXTRAOPTIONS}{'bios.bootDeviceClasses'} and 
        $self->{EXTRAOPTIONS}{'bios.bootDeviceClasses'} eq "allow:net,hd") {
        if (Array::Compare->new->simple_compare($self->{BOOTORDER},["net"])) {
            $result = 1;
        }
    }
    Debug("forcenetboot(".$self->name.")=".($result ? "TRUE" : "FALSE"));
    return $result;
}

sub activate_forcenetboot {
    my $self = shift;
    $self->poweroff;
    setVmExtraOpts( $self->_vm_view_or_uuid, "bios.bootDeviceClasses", "allow:net,hd" );
    setVmBootOrderToNetwork( $self->_vm_view_or_uuid );
    $self->poweron;
}

sub set_custom_value {
    my ($self,$key,$value) = @_;
    return setVmCustomValue( $self->_vm_view_or_uuid, $key, $value );
}

sub reboot_guest {
    my $self = shift;
    return perform_reboot_guest( $self->_vm_view_or_uuid );
}

sub reset {
    my $self = shift;
    return perform_reset( $self->_vm_view_or_uuid );
}

sub poweroff {
    my $self = shift;
    return perform_poweroff( $self->_vm_view_or_uuid );
}

sub poweron {
    my $self = shift;
    return perform_poweron( $self->_vm_view_or_uuid );
}

sub destroy {
    my $self = shift;
    return perform_destroy( $self->_vm_view_or_uuid);
}

1;
