#!/usr/bin/env ruby

REGEXPS = {
    # as it turns out these regexps may not work
    # https://bugs.gentoo.org/show_bug.cgi?id=523720
    # besides checks should be happen in other place
    'local'  => Regexp.new("([\\w\\/\\-\\+]+:)?([\\w\\+\\-]+)(?:\\s+-\\s+)(.*)"),
    'expand' => Regexp.new('([\\w\\+\\-@]+)(?:\\s+-\\s+)(.*)'),
    'hidden' => Regexp.new('([\\w\\+\\-]+)(?:\\s+-\\s+)(.*)'),
    'global' => Regexp.new('([\\w\\+\\-]+)(?:\\s+-\\s+)(.*)'),
}

p 'To be implemented. See source for details. Bue'
