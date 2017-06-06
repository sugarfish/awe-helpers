#!/usr/bin/env ruby

###
# This script uses the aws cli. It requires a valid key and secret.
###

require 'json'

class IAM
  def initialize(arg0, arg1)
    if arg0.nil? || (!(['-a', '--users'].include? arg0) && arg1.nil?)
      show_help()
    else
      case arg0
      when '-a'
        list_all_keys()
      when '-k'
        find_key(arg1)
      when '-u'
        list_user_data(arg1)
      when '--users'
        list_usernames()
      end
    end
  end

  def find_key(key)
    ak = get_access_key(key)
    if !ak.nil?
      print "Owner    : #{ak['UserName']}\n\n"
      print "Last Used: #{ak['AccessKeyLastUsed']['LastUsedDate']}\n"
      print "Service  : #{ak['AccessKeyLastUsed']['ServiceName']}\n\n"
    end
  end

  def list_user_data(user)
    ud = get_user(user)
    if !ud.nil?
      ud['AccessKeyMetadata'].each do |key|
        print "Key    : #{key['AccessKeyId']}\n"
        print "Created: #{key['CreateDate']}\n"
        print "Status : #{key['Status']}\n\n"
      end
    end
  end

  def list_all_keys
    u = list_users()
    if !u.nil?
      ucount = u['Users'].size
      uc = 0
      u['Users'].each do |user|
        print "User   : #{user['UserName']}\n"
        print "Created: #{user['CreateDate']}\n\n"

        print "Group(s): "
        g = list_groups(user)
        gcount = g['Groups'].size
        if gcount == 0
          print "(none)"
        else
          gc = 0
          g['Groups'].each do |group|
            print "#{group['GroupName']}"
            gc += 1
            if gc < gcount
              print ", "
            end
          end
        end
        print "\n\n"

        print "Key(s):\n"
        k = list_access_keys(user)
        k['AccessKeyMetadata'].each do |key|
          print "\tId     : #{key['AccessKeyId']}\n"
          print "\tCreated: #{key['CreateDate']}\n"
          print "\tStatus : #{key['Status']}\n\n"
        end

        uc += 1
        if uc < ucount
          print "............................................................\n"
        end
      end
    end
  end

  def list_usernames()
    u = list_users()
    if !u.nil?
      ucount = u['Users'].size
      uc = 0
      u['Users'].each do |user|
        print "#{user['UserName']}"
        uc += 1
        if uc < ucount
          print ", "
        else
          print "\n\n"
        end
      end
    end
  end

  def get_access_key(key)
    result = `aws iam get-access-key-last-used --access-key-id #{key}`
    if valid_json?(result)
      return JSON.parse(result)
    else
      return nil
    end
  end

  def get_user(user)
    result = `aws iam list-access-keys --user-name #{user}`
    if valid_json?(result)
      return JSON.parse(result)
    else
      return nil
    end
  end

  def list_users
    result = `aws iam list-users --no-paginate`
    if valid_json?(result)
      return JSON.parse(result)
    else
      return nil
    end
  end

  def list_groups(user)
    result = `aws iam list-groups-for-user --user-name #{user['UserName']}`
    if valid_json?(result)
      return JSON.parse(result)
    else
      return nil
    end
  end

  def list_access_keys(user)
    result = `aws iam list-access-keys --user-name #{user['UserName']}`
    if valid_json?(result)
      return JSON.parse(result)
    else
      return nil
    end
  end

  def show_help
    print "Usage:\n\n"
    print "--users\t\tList all users.\n"
    print "-a\t\tList all users, groups, keys.\n"
    print "-k\t\tList details for a given access key.\n"
    print "-u\t\tList all access keys for a given user.\n\n"
  end

  def valid_json?(json)
    JSON.parse(json)
    return true
    rescue JSON::ParserError => e
    return false
  end
end

IAM.new(ARGV[0], ARGV[1])

