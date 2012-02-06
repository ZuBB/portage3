#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'fileutils'
require 'optparse'
require 'tools'

# hash with options
options = Hash.new.merge!(OPTIONS)
portage_home = get_full_tree_path(options)
FileUtils.cd(portage_home)

`sed -i.bak -e '18d' ./dev-vcs/git/git-1.7.2.5.ebuild`
`sed -i.bak -e '22,28d' ./dev-vcs/git/git-1.7.2.5.ebuild`

`sed -i.bak -e '18d' ./dev-vcs/git/git-1.7.3.4-r1.ebuild`
`sed -i.bak -e '22,28d' ./dev-vcs/git/git-1.7.3.4-r1.ebuild`

`sed -i.bak -e '182d' ./media-video/mplayer/mplayer-1.0_rc4_p20110322-r1.ebuild`
`sed -i.bak -e '183,185d' ./media-video/mplayer/mplayer-1.0_rc4_p20110322-r1.ebuild`

`sed -i.bak -e '175d' ./media-video/mplayer/mplayer-1.0_rc4_p20111215.ebuild`
`sed -i.bak -e '176,178d' ./media-video/mplayer/mplayer-1.0_rc4_p20111215.ebuild`

`sed -i.bak -e '161d' ./media-video/mplayer/mplayer-1.0_rc4_p20120105.ebuild`
`sed -i.bak -e '162,164d' ./media-video/mplayer/mplayer-1.0_rc4_p20120105.ebuild`

`sed -i.bak -e '161d' ./media-video/mplayer/mplayer-1.0_rc4_p20120109.ebuild`
`sed -i.bak -e '162,164d' ./media-video/mplayer/mplayer-1.0_rc4_p20120109.ebuild`

`sed -i.bak -e '161d' ./media-video/mplayer/mplayer-1.0_rc4_p20120128.ebuild`
`sed -i.bak -e '162,164d' ./media-video/mplayer/mplayer-1.0_rc4_p20120128.ebuild`

`sed -i.bak -e '161,163d' ./media-video/mplayer/mplayer-9999.ebuild`
`sed -i.bak -e '162d' ./media-video/mplayer/mplayer-9999.ebuild`

`sed -i.bak 's/=/XXX/' ./games-strategy/openxcom/openxcom-9999.ebuild`

