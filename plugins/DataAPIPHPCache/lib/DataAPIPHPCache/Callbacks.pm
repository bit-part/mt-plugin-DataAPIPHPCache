package DataAPIPHPCache::Callbacks;
use strict;
use warnings;
use Cwd;
use constant DataAPIVersion => 'v1';

sub clear_data_api_cache {
    my ($cb, $app, $obj, $orig_obj) = @_;
    my $plugin = MT->component('DataAPIPHPCache');
    my $method = $cb->{'method'};
    my $method_object = $method;
    my $method_type = $method;
    if ($method eq 'MT::Comment::post_save') {
        $method_object = 'comment';
        $method_type = 'save';
    }
    else {
        $method_object =~ s/MT::App::CMS::cms_post_([^\.]+)\.(.+)/$2/;
        $method_type =~ s/MT::App::CMS::cms_post_([^\.]+)\.(.+)/$1/
    }
    my $objects = {
        website => 'sites',
        blog => 'sites',
        entry => 'entries',
        category => 'categories',
        comment => 'comments',
        # ping => 'trackbacks',
    };
    my $object_name = $objects->{$method_object};

    my $site_id = ($app->blog) ? $app->blog->id : 0;
    my $object_id = ($obj->id) ? $obj->id : 0;

    # Set Support Directory Path
    my $cache_dir_name;
    my $cache_dir_path;
    unless ($cache_dir_name = $plugin->get_config_value('data_api_cache_dir', 'system')) {
        $cache_dir_name = 'data-api-php-cache';
    }
    if (MT->config->SupportDirectoryPath) {
        $cache_dir_path = File::Spec->catdir(MT->config->SupportDirectoryPath, $cache_dir_name, DataAPIVersion, 'sites');
    }
    else {
        $cache_dir_path = File::Spec->catdir(MT->config->StaticFilePath, 'support', $cache_dir_name, DataAPIVersion, 'sites');
    }

    my $home_dir = Cwd::getcwd();

    # Set Cache Directory Path
    my @clear_cache_dir;
    my @clear_cache_file_dir;
    if ($object_name eq 'sites') {
        push(@clear_cache_dir, File::Spec->catdir($cache_dir_path, $site_id));
    }
    else {
        @clear_cache_file_dir = (File::Spec->catdir($cache_dir_path, $site_id, $object_name));
        if ($object_id) {
            if ($object_name eq 'entries') {
                push(@clear_cache_dir, File::Spec->catdir($cache_dir_path, $site_id, $object_name, $object_id));
            }
            elsif ($object_name eq 'comments') {
                push(@clear_cache_dir, File::Spec->catdir($cache_dir_path, $site_id, $object_name, $object_id));
                if ($obj->entry_id) {
                    push(@clear_cache_dir, File::Spec->catdir($cache_dir_path, $site_id, 'entries', $obj->entry_id, $object_name));
                }
            }
        }
    }

    if (defined(@clear_cache_dir)) {
        my $fmgr = MT::FileMgr->new('Local');
        require File::Find;
        foreach my $dir (@clear_cache_dir) {
            File::Find::find(
                {
                    wanted => sub {
                        -d $_ ? rmdir $_ : $fmgr->delete($_);
                    },
                    bydepth  => 1,
                    no_chdir => 1,
                },
                $dir
            );
        }
    }
    if (defined(@clear_cache_file_dir)) {
        foreach my $dir (@clear_cache_file_dir) {
            if (-d $dir) {
                chdir($dir) or die $!;
                opendir(DIR, $dir);
                my @file_list = glob('*.json');
                foreach my $file (@file_list) {
                    unlink($file);
                }
                closedir(DIR);
            }
        }
    }
    chdir($home_dir) or die $!;
    return 1;
}

sub post_delete_objects {
    my ($cb, $app, $obj) = @_;
}

1;
