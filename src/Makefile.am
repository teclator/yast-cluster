# Sources for cluster

module_DATA = \
  modules/Cluster.rb

client_DATA = \
  clients/cluster_proposal.rb \
  clients/cluster_auto.rb \
  clients/cluster.rb

yncludedir = @yncludedir@/cluster
ynclude_DATA = \
  include/cluster/dialogs.rb \
  include/cluster/common.rb \
  include/cluster/complex.rb \
  include/cluster/helps.rb \
  include/cluster/wizards.rb

scrconf_DATA = \
  scrconf/openais.scr \
  scrconf/cfg_pacemaker.scr \
  scrconf/cfg_openais.scr \
  scrconf/sysconfig_conntrackd.scr \
  scrconf/csync2_ha.scr

agent_SCRIPTS = \
  servers_non_y2/ag_openais

desktop_DATA = \
  desktop/cluster.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(agent_SCRIPTS) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common