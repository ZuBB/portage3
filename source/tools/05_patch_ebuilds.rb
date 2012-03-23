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

`sed -i.bak1 -e '18d' ./dev-vcs/git/git-1.7.2.5.ebuild`
`sed -i.bak2 -e '22,28d' ./dev-vcs/git/git-1.7.2.5.ebuild`

`sed -i.bak1 -e '18d' ./dev-vcs/git/git-1.7.3.4-r1.ebuild`
`sed -i.bak2 -e '22,28d' ./dev-vcs/git/git-1.7.3.4-r1.ebuild`

`sed -i.bak1 -e '182d' ./media-video/mplayer/mplayer-1.0_rc4_p20110322-r1.ebuild`
`sed -i.bak2 -e '183,185d' ./media-video/mplayer/mplayer-1.0_rc4_p20110322-r1.ebuild`

`sed -i.bak1 -e '161d' ./media-video/mplayer/mplayer-1.0_rc4_p20120213.ebuild`
`sed -i.bak2 -e '162,164d' ./media-video/mplayer/mplayer-1.0_rc4_p20120213.ebuild`

`sed -i.bak1 -e '161,163d' ./media-video/mplayer/mplayer-9999.ebuild`
`sed -i.bak2 -e '162d' ./media-video/mplayer/mplayer-9999.ebuild`

`sed -i.bak1 's/\[\[ \${PV} = 9999 \]\] \&\& //' ./games-strategy/openxcom/openxcom-9999.ebuild`
`sed -i.bak2 's/\[\[ \${PV} = 9999 \]\] || //' ./games-strategy/openxcom/openxcom-9999.ebuild`

`sed -i.bak1 -e '8,15d' ./media-libs/libvpx/libvpx-0.9.6.ebuild`
`sed -i.bak2 -e '12d' ./media-libs/libvpx/libvpx-0.9.6.ebuild`

`sed -i.bak1 -e '8,15d' ./media-libs/libvpx/libvpx-0.9.7-r1.ebuild`
`sed -i.bak2 -e '12d' ./media-libs/libvpx/libvpx-0.9.7-r1.ebuild`

`sed -i.bak1 -e '8,15d' ./media-libs/libvpx/libvpx-0.9.7.ebuild`
`sed -i.bak2 -e '12d' ./media-libs/libvpx/libvpx-0.9.7.ebuild`

`sed -i.bak1 -e '8,15d' ./media-libs/libvpx/libvpx-1.0.0.ebuild`
`sed -i.bak2 -e '11d' ./media-libs/libvpx/libvpx-1.0.0.ebuild`

`sed -i.bak1 -e '8d' ./media-libs/libvpx/libvpx-9999.ebuild`
`sed -i.bak2 -e '11,18d' ./media-libs/libvpx/libvpx-9999.ebuild`

# https://bugs.gentoo.org/show_bug.cgi?id=409337
`sed -i.bak1 -e '12,13d' ./sys-infiniband/libcxgb3/libcxgb3-1.2.5.ebuild`
`sed -i.bak1 -e '13,14d' ./sys-infiniband/libehca/libehca-1.2.2.ebuild`
