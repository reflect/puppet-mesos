# Class: mesos::config
#
# This module manages the mesos configuration directories
#
# Parameters:
#  [*log_dir*]        - directory for logging, (default: '/var/log/mesos')
#  [*conf_dir*]       - directory for configuration files (default: /etc/mesos)
#  [*manage_zk_file*] - flag whether module manages /etc/mesos/zk (default: true)
#  [*owner*]          - owner of configuration files
#  [*group*]          - group of configuration files
#  [*zookeeper_url*]  - string of ZooKeeper servers e.g. `zk://10.0.0.1/mesos`
#
# This class should not be included directly,
# always use 'mesos::slave' or 'mesos:master'
#
class mesos::config(
  $log_dir        = undef,
  $ulimit         = 8192,
  $conf_dir       = '/etc/mesos',
  $conf_file      = '/etc/default/mesos',
  $manage_zk_file = true,
  $owner          = 'root',
  $group          = 'root',
  $env_var        = {},
  $zookeeper_url  = undef,
){
  validate_bool($manage_zk_file)

  if $log_dir {
    file { $log_dir:
      ensure => directory,
      owner  => $owner,
      group  => $group,
    }
  }

  file { $conf_dir:
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  if $conf_file {
    file { $conf_file:
      ensure  => 'present',
      content => template('mesos/default.erb'),
      owner   => $owner,
      group   => $group,
      mode    => '0644',
      require => Package['mesos'],
    }
  }

  if $manage_zk_file {
    # file containing only zookeeper URL
    file { '/etc/mesos/zk':
      ensure  => empty($zookeeper_url) ? {
        true  => absent,
        false => present,
      },
      content => $zookeeper_url,
      owner   => $owner,
      group   => $group,
    }
  }

}
