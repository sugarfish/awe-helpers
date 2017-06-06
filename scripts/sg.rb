#!/usr/bin/env ruby

###
# This script uses the aws cli. It requires a valid key and secret.
###

require 'json'

class SG
  def initialize
    list_all_security_groups
  end

  def list_all_security_groups
    sg = list_security_groups()
    types = {
      22   => 'ssh',
      25   => 'smtp',
      53   => 'dns',
      80   => 'http',
      110  => 'pop3',
      143  => 'imap',
      389  => 'ldap',
      443  => 'https',
      465  => 'smtps',
      993  => 'imaps',
      995  => 'pop3s',
      1433 => 'ms sql',
      2049 => 'nfs',
      3306 => 'mysql/aurora',
      3389 => 'rdp',
      5439 => 'redshift',
      5432 => 'postgresql',
      1521 => 'oracle-rds',
      5985 => 'winrm-http',
      5986 => 'winrm-https'
    }
    if !sg.nil?
      sg['SecurityGroups'].each do |group|
        print "#{group['GroupName']} (#{group['GroupId']}) / \"#{group['Description']}\"\n"

        group['IpPermissions'].each do |perm|

          range = get_port_range(perm['IpProtocol'], perm['FromPort'], perm['ToPort'])

          tabs = 4 - Integer(range.length / 4)
          for i in 0..tabs
            range += "\t"
          end

          if perm['IpProtocol'] != "-1"
            protocol = perm['IpProtocol']
          else
            if protocol.nil?
              protocol = 'all'
           end
         end
          tabs = 4 - Integer(protocol.length / 4)
          for i in 0..tabs
            protocol += "\t"
          end

          type = types[perm['FromPort']] if type.nil?

          if type.nil?
            if perm['IpProtocol'] == 'icmp' && perm['FromPort'] = 'n/a'
              type = 'all icmp - ipv4'
            else
              case perm['IpProtocol']
              when 'tcp'
                type = 'custom tcp'
              when 'udp'
                type = 'custom udp'
              else
                type = 'all traffic'
              end
            end
          end

          tabs = 4 - Integer(type.length / 4)
          for i in 0..tabs
            type += "\t"
          end

          if perm['IpRanges'].size > 0
            perm['IpRanges'].each do |ip|
              print "#{type}#{protocol}#{range}#{ip['CidrIp']}\n"
            end
          end

          if perm['UserIdGroupPairs'].size > 0
            perm['UserIdGroupPairs'].each do |pair|
              groupname = get_groupname(pair['GroupId'])
              if !groupname.nil?
                print "#{type}#{protocol}#{range}#{pair['GroupId']} (#{groupname})\n"
              else
                print "#{type}#{protocol}#{range}#{pair['GroupId']}\n"
              end
            end
          end

        end
        print "\n"
      end
    end
  end

  def list_security_groups
    result=`aws ec2 describe-security-groups`
    if valid_json?(result)
      return JSON.parse(result)
    else
      return nil
    end
  end

  def get_port_range(protocol, from, to)
    range = "n/a"

    if protocol != -1
      if protocol == "-1"
        range = "all"
      else
        if from != -1 || from == ""
          if from != to
           range = "#{from} - #{to}"
         else
           range = "#{from}"
          end
        else
          if from == -1 && to == -1
           range = "n/a"
          else
            range = "none"
          end
        end
      end
    end

    return range
  end

  def get_groupname(groupid)
    result = `aws ec2 describe-security-groups --group-ids #{groupid}`
    if valid_json?(result)
      sg = JSON.parse(result)
      return sg['SecurityGroups'][0]['GroupName']
    else
      return "MISSING SECURITY GROUP"
    end
  end

  def valid_json?(json)
    JSON.parse(json)
    return true
    rescue JSON::ParserError => e
    return false
  end
end

SG.new()

