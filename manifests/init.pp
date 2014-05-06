class appie {
    file { "/tmp/appie-1.8.1.deb":
        ensure => file,
        source => "puppet:///modules/appie/appie-1.8.1.deb",
    }

    exec { "dpkg -i /tmp/appie-1.8.1.deb":
        alias => "install appie",
        path => [ "/bin", "/usr/bin", "/usr/sbin", "/sbin" ],
        require => File["/tmp/appie-1.8.1.deb"]
    }

    file { "/etc/sudoers.d/appie_applications":
        source => "puppet:///modules/appie/appie_applications",
        owner => root,
        group => root,
    }

    define app($app, $source) {
        #exec { "appie app:mkenv $app $name":
        #    path => [ "/bin", "/usr/bin", "/usr/sbin", "/sbin" ],
        #}

        $home_dir = "/opt/APPS/$app/$name"
        $ssh_dir = "$home_dir/.ssh"
        $user = "app-$app-$name"

        group { $user:
            ensure => 'present',
        }
        user { $user:
            ensure => 'present',
            gid => $user,
            home => $home_dir,
            managehome => true,
            require => Group[$user],
        }

        file { $ssh_dir:
            require => User[$user],
            ensure => directory,
            owner => $user,
            group => $user,
            mode => '0700',
        }

        # Store SSH keys so we can pull from git.gw20e.com
        # TODO: this probably isn't secure..
        file { "${ssh_dir}/id_rsa":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => 600,
            source => "puppet:///modules/appie/ssh/id_rsa"
        }
        file { "${ssh_dir}/id_rsa.pub":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => 600,
            source => "puppet:///modules/appie/ssh/id_rsa.pub"
        }
        file { "${ssh_dir}/known_hosts":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => 600,
            source => "puppet:///modules/appie/ssh/known_hosts"
        }
        file { "${ssh_dir}/authorized_keys":
            require => File[$ssh_dir],
            owner => $user,
            group => $user,
            mode => 600,
            source => "puppet:///modules/appie/ssh/authorized_keys"
        }

        vcsrepo { "${home_dir}/project":
            require => [
                User[$user],
                File["${ssh_dir}/known_hosts"],
                File["${ssh_dir}/id_rsa"],
            ],
            ensure => present,
            user => $user,
            provider => git,
            source => $source,
            #revision => $buildout_rev,
        }

    }
}
