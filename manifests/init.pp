# == Class: mesos
#
# This module manages mesos installation
#
# === Examples
#
#      class{ 'mesos':
#         zookeeper => ['192.168.1.1:2181', '192.168.1.1:2181'],
#      }
#
# === Parameters
#
#  [*zookeeper*]
#    An array of ZooKeeper ip's (with port) (will be converted to a zk url)
#
#  [*zookeeper_path*]
#    Mesos namespace in ZooKeeper (last part of the zk:// URL, e.g. `zk://192.168.1.1/mesos`)
#
#  [*master*]
#    If `zookeeper` is empty, master value is used
#
#  [*listen_address*]
#    Could be a fact like `$::ipaddress` or explicit ip address (String).
#
#  [*single_role*]
#    When enabled each machine is expected to run either master or slave service.
#
# === Authors
#
# Tomas Barton <barton.tomas@gmail.com>
#
# === Copyright
#
# Copyright 2013-2016 Tomas Barton
#
class mesos(
  $ensure          = 'present',
  # if version is not defined, ensure will be used
  $version         = undef,
  # master and slave creates separate logs automatically
  # TODO: currently not used
  $log_dir          = undef,
  $conf_dir         = '/etc/mesos',
  $conf_file        = '/etc/default/mesos',
  $manage_service   = true,
  $zookeeper        = [],
  $zk_path          = 'mesos',
  $zk_default_port  = 2181,
  $master           = '127.0.0.1',
  $master_port      = 5050,
  $manage_zk_file   = true,
  $owner            = 'root',
  $group            = 'root',
  $listen_address   = undef,
  $repo             = undef,
  $env_var          = {},
  $ulimit           = 8192,
  $manage_python    = false,
  $python_package   = 'python',
  $force_provider   = undef, #temporary workaround for starting services
  $use_hiera        = false,
  $force_provider   = undef,
  $single_role      = true,
  $manage_zookeeper = false,
) {
  validate_hash($env_var)
  validate_bool($manage_zookeeper)
}
