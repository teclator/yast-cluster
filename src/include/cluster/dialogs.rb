# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	include/cluster/wizards.ycp
# Package:	Configuration of cluster
# Summary:	Wizards definitions
# Authors:	Cong Meng <cmeng@novell.com>
#
# $Id: wizards.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module ClusterDialogsInclude
    def initialize_cluster_dialogs(include_target)
      textdomain "cluster"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Cluster"
      Yast.import "IP"
      Yast.import "Popup"
      Yast.import "Service"
      Yast.import "Report"
      Yast.import "CWMFirewallInterfaces"
      Yast.import "SuSEFirewall"
      Yast.import "SuSEFirewallServices"

      Yast.include include_target, "cluster/helps.rb"
      Yast.include include_target, "cluster/common.rb"

      @csync2_suggest_files = [
        "/etc/corosync/corosync.conf",
        "/etc/corosync/authkey",
        "/etc/sysconfig/pacemaker",
        "/etc/drbd.d",
        "/etc/lvm/lvm.conf",
        "/etc/multipath.conf",
        "/etc/ha.d/ldirectord.cf",
        "/etc/ctdb/nodes",
        "/etc/samba/smb.conf",
        "/etc/sysconfig/pacemaker",
        "/etc/sysconfig/openais",
        "/etc/csync2/csync2.cfg",
        "/etc/csync2/key_hagroup"
      ]

      @csync2_port = "30865"
    end

    # return `cacel or a string
    def text_input_dialog(title, value)
      ret = nil

      UI.OpenDialog(
        MarginBox(
          1,
          1,
          VBox(
            MinWidth(100, TextEntry(Id(:text), title, value)),
            VSpacing(1),
            Right(
              HBox(
                PushButton(Id(:ok), _("OK")),
                PushButton(Id(:cancel), _("Cancel"))
              )
            )
          )
        )
      )

      ret = UI.UserInput
      ret = UI.QueryWidget(:text, :Value) if ret == :ok
      UI.CloseDialog
      deep_copy(ret)
    end


    def ValidateCommunication
      i = 0
      if IP.Check(Convert.to_string(UI.QueryWidget(Id(:bindnetaddr1), :Value))) == false
        Popup.Message("The Bind Network Address has to be fulfilled")
        UI.SetFocus(:bindnetaddr1)
        return false
      end

      if UI.QueryWidget(Id(:transport), :Value) == "udpu"
        i = 0
        Builtins.foreach(Cluster.memberaddr1) do |value|
          if IP.Check(value) == false
            UI.ChangeWidget(:memberaddr1, :CurrentItem, i)
            i = 0
            raise Break
          end
          i = Ops.add(i, 1)
        end
        if i == 0
          UI.SetFocus(:memberaddr1)
          Popup.Message("The Member Address has to be fulfilled")
          return false
        end
      else
        if IP.Check(Convert.to_string(UI.QueryWidget(Id(:mcastaddr1), :Value))) == false
          Popup.Message("The Multicast Address has to be fulfilled")
          UI.SetFocus(:mcastaddr1)
          return false
        end
      end

      if !Builtins.regexpmatch(
          Convert.to_string(UI.QueryWidget(Id(:mcastport1), :Value)),
          "^[0-9]+$"
        )
        Popup.Message("The Multicast port must be a positive integer")
        UI.SetFocus(Id(:mcastport1))
        return false
      end

      if UI.QueryWidget(Id(:autoid), :Value) == false
        noid = Convert.to_string(UI.QueryWidget(Id(:nodeid), :Value))
        s = Builtins.regexpmatch(noid, "^[0-9]+$")
        if !s
          Popup.Message("Node ID has to be a positive integer")
          UI.SetFocus(Id(:nodeid))
          return false
        end
        i2 = Builtins.tointeger(noid)
        if i2 == 0
          Popup.Message("NodeID 0 is reserved")
          UI.SetFocus(Id(:nodeid))
          return false
        end
      end

      if UI.QueryWidget(Id(:enable2), :Value) == true
        if IP.Check(
            Convert.to_string(UI.QueryWidget(Id(:bindnetaddr2), :Value))
          ) == false
          Popup.Message("The Bind Network Address has to be fulfilled")
          UI.SetFocus(:bindnetaddr2)
          return false
        end

        if UI.QueryWidget(Id(:transport), :Value) == "udpu"
          i = 0
          Builtins.foreach(Cluster.memberaddr2) do |value|
            if IP.Check(value) == false
              UI.ChangeWidget(:memberaddr2, :CurrentItem, i)
              i = 0
              raise Break
            end
            i = Ops.add(i, 1)
          end
          if i == 0
            UI.SetFocus(:memberaddr2)
            Popup.Message("The Member Address has to be fulfilled")
            return false
          end
        else
          if IP.Check(
              Convert.to_string(UI.QueryWidget(Id(:mcastaddr2), :Value))
            ) == false
            Popup.Message("The Multicast Address has to be fulfilled")
            UI.SetFocus(:mcastaddr2)
            return false
          end
        end

        if !Builtins.regexpmatch(
            Convert.to_string(UI.QueryWidget(Id(:mcastport2), :Value)),
            "^[0-9]+$"
          )
          Popup.Message("The Multicast port must be a positive integer")
          UI.SetFocus(Id(:mcastport2))
          return false
        end
      end

      true
    end

    def SaveCommunicationToConf
      SCR.Write(
        path(".openais.totem.interface.interface0.bindnetaddr"),
        Convert.to_string(UI.QueryWidget(Id(:bindnetaddr1), :Value))
      )
      SCR.Write(
        path(".openais.totem.interface.interface0.mcastaddr"),
        Convert.to_string(UI.QueryWidget(Id(:mcastaddr1), :Value))
      )
      SCR.Write(
        path(".openais.totem.interface.interface0.mcastport"),
        Convert.to_string(UI.QueryWidget(Id(:mcastport1), :Value))
      )

      if UI.QueryWidget(Id(:enable2), :Value) == false
        SCR.Write(path(".openais.totem.interface.interface1"), "")
      else
        SCR.Write(
          path(".openais.totem.interface.interface1.bindnetaddr"),
          Convert.to_string(UI.QueryWidget(Id(:bindnetaddr2), :Value))
        )
        SCR.Write(
          path(".openais.totem.interface.interface1.mcastaddr"),
          Convert.to_string(UI.QueryWidget(Id(:mcastaddr2), :Value))
        )
        SCR.Write(
          path(".openais.totem.interface.interface1.mcastport"),
          Convert.to_string(UI.QueryWidget(Id(:mcastport2), :Value))
        )
      end

      if UI.QueryWidget(Id(:autoid), :Value) == true
        SCR.Write(path(".openais.totem.autoid"), "yes")
        SCR.Write(path(".openais.totem.nodeid"), "0")
      else
        SCR.Write(
          path(".openais.totem.nodeid"),
          Convert.to_string(UI.QueryWidget(Id(:nodeid), :Value))
        )
        SCR.Write(path(".openais.totem.autoid"), "no")
      end

      SCR.Write(
        path(".openais.totem.rrpmode"),
        Convert.to_string(UI.QueryWidget(Id(:rrpmode), :Value))
      )

      nil
    end

    def SaveCommunication
      Cluster.bindnetaddr1 = Convert.to_string(
        UI.QueryWidget(Id(:bindnetaddr1), :Value)
      )
      Cluster.bindnetaddr2 = Convert.to_string(
        UI.QueryWidget(Id(:bindnetaddr2), :Value)
      )
      Cluster.mcastaddr1 = Convert.to_string(
        UI.QueryWidget(Id(:mcastaddr1), :Value)
      )
      Cluster.mcastaddr2 = Convert.to_string(
        UI.QueryWidget(Id(:mcastaddr2), :Value)
      )
      Cluster.mcastport1 = Convert.to_string(
        UI.QueryWidget(Id(:mcastport1), :Value)
      )
      Cluster.mcastport2 = Convert.to_string(
        UI.QueryWidget(Id(:mcastport2), :Value)
      )
      Cluster.enable2 = Convert.to_boolean(UI.QueryWidget(Id(:enable2), :Value))
      Cluster.autoid = Convert.to_boolean(UI.QueryWidget(Id(:autoid), :Value))
      Cluster.nodeid = Convert.to_string(UI.QueryWidget(Id(:nodeid), :Value))
      Cluster.rrpmode = Convert.to_string(UI.QueryWidget(Id(:rrpmode), :Value))
      Cluster.transport = Convert.to_string(
        UI.QueryWidget(Id(:transport), :Value)
      )

      nil
    end


    def calc_network_addr(ip, mask)
      str = IP.IPv4ToBits(ip)
      str = Builtins.substring(str, 0, Builtins.tointeger(mask))
      while Ops.less_than(Builtins.size(str), 32)
        str = Ops.add(str, "0")
      end
      IP.BitsToIPv4(str)
    end


    def transport_switch
      udp = Convert.to_string(UI.QueryWidget(Id(:transport), :Value)) == "udp"
      enable2 = Convert.to_boolean(UI.QueryWidget(Id(:enable2), :Value))

      enable1 = udp
      enable2 = udp && enable2

      UI.ChangeWidget(Id(:mcastaddr1), :Enabled, enable1)
      UI.ChangeWidget(Id(:memberaddr1), :Enabled, !enable1)
      UI.ChangeWidget(Id(:memberaddr1_add), :Enabled, !enable1)
      UI.ChangeWidget(Id(:memberaddr1_del), :Enabled, !enable1)
      UI.ChangeWidget(Id(:memberaddr1_edit), :Enabled, !enable1)

      UI.ChangeWidget(Id(:mcastaddr2), :Enabled, enable2)
      UI.ChangeWidget(Id(:memberaddr2), :Enabled, !enable2)
      UI.ChangeWidget(Id(:memberaddr2_add), :Enabled, !enable2)
      UI.ChangeWidget(Id(:memberaddr2_del), :Enabled, !enable2)
      UI.ChangeWidget(Id(:memberaddr2_edit), :Enabled, !enable2)

      nil
    end


    def CommunicationLayout
      result = {}

      result = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "/sbin/ip addr show scope global | grep inet | awk '{print $2}' | awk -F'/' '{print $1, $2}'"
        )
      )

      existing_ips = []
      if Builtins.size(Ops.get_string(result, "stdout", "")) != 0
        ip_masks = Builtins.splitstring(
          Ops.get_string(result, "stdout", ""),
          "\n"
        )
        Builtins.foreach(ip_masks) do |s|
          ip_mask_list = Builtins.splitstring(s, " ")
          ip = Ops.get(ip_mask_list, 0, "")
          mask = Ops.get(ip_mask_list, 1, "")
          ip4 = false
          ip4 = IP.Check4(ip)
          if ip4
            existing_ips = Builtins.add(
              existing_ips,
              calc_network_addr(ip, mask)
            )
          end
        end
      end

      transport = ComboBox(
        Id(:transport),
        Opt(:hstretch, :notify),
        _("Transport:"),
        ["udp", "udpu"]
      )

      iface = Frame(
        _("Channel"),
        VBox(
          ComboBox(
            Id(:bindnetaddr1),
            Opt(:editable, :hstretch, :notify),
            _("Bind Network Address:"),
            Builtins.toset(existing_ips)
          ),
          InputField(
            Id(:mcastaddr1),
            Opt(:hstretch, :notify),
            _("Multicast Address:")
          ),
          InputField(Id(:mcastport1), Opt(:hstretch), _("Multicast Port:")),
          Left(Label(_("Member Address:"))),
          SelectionBox(Id(:memberaddr1), ""),
          HBox(
            PushButton(Id(:memberaddr1_add), "Add"),
            PushButton(Id(:memberaddr1_del), "Del"),
            PushButton(Id(:memberaddr1_edit), "Edit")
          )
        )
      )

      riface = CheckBoxFrame(
        Id(:enable2),
        Opt(:notify),
        _("Redundant Channel"),
        false,
        VBox(
          ComboBox(
            Id(:bindnetaddr2),
            Opt(:editable, :hstretch, :notify),
            "Bind Network Address:",
            existing_ips
          ),
          InputField(Id(:mcastaddr2), Opt(:hstretch), "Multicast Address:"),
          InputField(Id(:mcastport2), Opt(:hstretch), "Multicast Port:"),
          Left(Label(_("Member Address:"))),
          SelectionBox(Id(:memberaddr2), ""),
          HBox(
            PushButton(Id(:memberaddr2_add), "Add"),
            PushButton(Id(:memberaddr2_del), "Del"),
            PushButton(Id(:memberaddr2_edit), "Edit")
          )
        )
      )

      nid = VBox(
        InputField(Id(:nodeid), Opt(:hstretch), "Node ID:"),
        Left(CheckBox(Id(:autoid), Opt(:notify), "Auto Generate Node ID", true))
      )

      rrpm = ComboBox(
        Id(:rrpmode),
        Opt(:hstretch),
        "rrp mode:",
        ["none", "active", "passive"]
      )

      contents = VBox(
        transport,
        HBox(VBox(iface, nid), VBox(riface, rrpm, VSpacing(1)))
      )

      my_SetContents("communication", contents)

      UI.ChangeWidget(Id(:bindnetaddr1), :Value, Cluster.bindnetaddr1)
      UI.ChangeWidget(Id(:mcastaddr1), :Value, Cluster.mcastaddr1)
      UI.ChangeWidget(Id(:mcastport1), :Value, Cluster.mcastport1)
      UI.ChangeWidget(Id(:enable2), :Value, Cluster.enable2)
      UI.ChangeWidget(Id(:bindnetaddr2), :Value, Cluster.bindnetaddr2)
      UI.ChangeWidget(Id(:mcastaddr2), :Value, Cluster.mcastaddr2)
      UI.ChangeWidget(Id(:mcastport2), :Value, Cluster.mcastport2)

      UI.ChangeWidget(Id(:autoid), :Value, Cluster.autoid)
      UI.ChangeWidget(Id(:nodeid), :Value, Cluster.nodeid)
      UI.ChangeWidget(Id(:transport), :Value, Cluster.transport)

      UI.ChangeWidget(Id(:rrpmode), :Value, Cluster.rrpmode)

      if UI.QueryWidget(Id(:autoid), :Value) == true
        UI.ChangeWidget(Id(:nodeid), :Enabled, false)
      end

      transport_switch

      nil
    end


    def fill_memberaddr_entries
      i = 0
      ret = 0
      current = 0
      items = []

      # remove duplicated elements
      Cluster.memberaddr1 = Ops.add(Cluster.memberaddr1, [])
      Cluster.memberaddr2 = Ops.add(Cluster.memberaddr2, [])

      i = 0
      items = []
      Builtins.foreach(Cluster.memberaddr1) do |value|
        items = Builtins.add(items, Item(Id(i), value))
        i = Ops.add(i, 1)
      end
      current = Convert.to_integer(UI.QueryWidget(:memberaddr1, :CurrentItem))
      current = 0 if current == nil
      current = Ops.subtract(i, 1) if Ops.greater_or_equal(current, i)
      UI.ChangeWidget(:memberaddr1, :Items, items)
      UI.ChangeWidget(:memberaddr1, :CurrentItem, current)

      i = 0
      items = []
      Builtins.foreach(Cluster.memberaddr2) do |value|
        items = Builtins.add(items, Item(Id(i), value))
        i = Ops.add(i, 1)
      end
      current = Convert.to_integer(UI.QueryWidget(:memberaddr2, :CurrentItem))
      current = 0 if current == nil
      current = Ops.subtract(i, 1) if Ops.greater_or_equal(current, i)
      UI.ChangeWidget(:memberaddr2, :Items, items)
      UI.ChangeWidget(:memberaddr2, :CurrentItem, current)

      nil
    end

    def CommunicationDialog
      ret = nil

      CommunicationLayout()

      while true
        fill_memberaddr_entries
        transport_switch

        ret = UI.UserInput

        if ret == :bindnetaddr1 || ret == :bindnetaddr2 || ret == :mcastaddr1 ||
            ret == :mcastaddr2
          ip6 = false
          netaddr = Convert.to_string(UI.QueryWidget(Id(ret), :Value))
          ip6 = IP.Check6(netaddr)
          if ip6
            UI.ChangeWidget(Id(:autoid), :Value, false)
            UI.ChangeWidget(Id(:nodeid), :Enabled, true)
            UI.ChangeWidget(Id(:autoid), :Enabled, false)
          else
            UI.ChangeWidget(Id(:autoid), :Enabled, true)
          end
          next
        end

        if ret == :autoid
          UI.ChangeWidget(
            Id(:nodeid),
            :Enabled,
            true != UI.QueryWidget(Id(:autoid), :Value)
          )
          next
        end

        if ret == :enable2
          if true == UI.QueryWidget(Id(:enable2), :Value)
            UI.ChangeWidget(Id(:rrpmode), :Value, "passive")
          else
            UI.ChangeWidget(Id(:rrpmode), :Value, "none")
          end
        end

        if ret == :memberaddr1_add
          ret = text_input_dialog(_("Enter a member address"), "")
          next if ret == :cancel
          Cluster.memberaddr1 = Builtins.add(
            Cluster.memberaddr1,
            Convert.to_string(ret)
          )
        end

        if ret == :memberaddr1_edit
          current = 0
          str = ""

          current = Convert.to_integer(
            UI.QueryWidget(:memberaddr1, :CurrentItem)
          )
          ret = text_input_dialog(
            _("Edit the member address"),
            Ops.get(Cluster.memberaddr1, current, "")
          )
          next if ret == :cancel
          Ops.set(Cluster.memberaddr1, current, Convert.to_string(ret))
        end

        if ret == :memberaddr1_del
          current = 0
          current = Convert.to_integer(
            UI.QueryWidget(:memberaddr1, :CurrentItem)
          )
          Cluster.memberaddr1 = Builtins.remove(Cluster.memberaddr1, current)
        end

        if ret == :memberaddr2_add
          ret = text_input_dialog(_("Enter a member address"), "")
          next if ret == :cancel
          Cluster.memberaddr2 = Builtins.add(
            Cluster.memberaddr2,
            Convert.to_string(ret)
          )
        end

        if ret == :memberaddr2_edit
          current = 0
          str = ""

          current = Convert.to_integer(
            UI.QueryWidget(:memberaddr2, :CurrentItem)
          )
          ret = text_input_dialog(
            _("Edit the member address"),
            Ops.get(Cluster.memberaddr2, current, "")
          )
          next if ret == :cancel
          Ops.set(Cluster.memberaddr2, current, Convert.to_string(ret))
        end

        if ret == :memberaddr2_del
          current = 0
          current = Convert.to_integer(
            UI.QueryWidget(:memberaddr2, :CurrentItem)
          )
          Cluster.memberaddr2 = Builtins.remove(Cluster.memberaddr2, current)
        end

        if ret == :next || ret == :back
          val = ValidateCommunication()
          if val == true
            SaveCommunication()
            break
          else
            ret = nil
            next
          end
        end

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if Builtins.contains(@DIALOG, Convert.to_string(ret))
          ret = Builtins.symbolof(Builtins.toterm(ret))
          val = ValidateCommunication()
          if val == true
            SaveCommunication()
            break
          else
            ret = nil
            Wizard.SelectTreeItem("communication")
            next
          end
        end

        Builtins.y2error("unexpected retcode: %1", ret)
      end

      deep_copy(ret)
    end

    def ValidateSecurity
      ret = true
      if UI.QueryWidget(Id(:secauth), :Value) == true
        thr = Convert.to_string(UI.QueryWidget(Id(:threads), :Value))
        s = Builtins.regexpmatch(thr, "^[0-9]+$")
        if !s
          Popup.Message("Number of threads must be integer")
          UI.SetFocus(Id(:threads))
          ret = false
        end
        i = Builtins.tointeger(thr)
        if i == 0
          Popup.Message("Number of threads must larger then 0")
          UI.SetFocus(Id(:threads))
          ret = false
        end
      end
      ret
    end

    def SaveSecurityToConf
      if UI.QueryWidget(Id(:secauth), :Value) == true
        SCR.Write(path(".openais.totem.secauth"), "on")
        SCR.Write(
          path(".openais.totem.threads"),
          Convert.to_string(UI.QueryWidget(Id(:threads), :Value))
        )
      else
        SCR.Write(path(".openais.totem.secauth"), "off")
        SCR.Write(path(".openais.totem.threads"), "")
      end

      nil
    end

    def SaveSecurity
      Cluster.secauth = Convert.to_boolean(UI.QueryWidget(Id(:secauth), :Value))
      Cluster.threads = Convert.to_string(UI.QueryWidget(Id(:threads), :Value))

      nil
    end

    def SecurityDialog
      ret = nil

      contents = VBox(
        VSpacing(1),
        CheckBoxFrame(
          Id(:secauth),
          Opt(:hstretch, :notify),
          _("Enable Security Auth"),
          true,
          VBox(
            InputField(Id(:threads), Opt(:hstretch), "Threads:"),
            VSpacing(1),
            Label(
              _(
                "For newly created cluster, push the button below to generate /etc/corosync/authkey."
              )
            ),
            Label(
              _(
                "To join an existing cluster, please copy /etc/corosync/authkey from other nodes manually."
              )
            ),
            PushButton(Id(:genf), Opt(:notify), "Generate Auth Key File")
          )
        ),
        VStretch()
      )

      my_SetContents("security", contents)

      UI.ChangeWidget(Id(:secauth), :Value, Cluster.secauth)

      UI.ChangeWidget(Id(:threads), :Value, Cluster.threads)

      while true
        ret = UI.UserInput

        if ret == :genf
          result = {}
          result = Convert.to_map(
            SCR.Execute(
              path(".target.bash_output"),
              "/usr/sbin/corosync-keygen"
            )
          )
          if Ops.get_integer(result, "exit", -1) != 0
            Popup.Message("Failed to create /etc/corosync/authkey")
          else
            Popup.Message("Create /etc/corosync/authkey succeeded")
          end
          next
        end

        if ret == :secauth
          if UI.QueryWidget(Id(:secauth), :Value) == true
            thr = Convert.to_string(UI.QueryWidget(Id(:threads), :Value))
            if thr == "" || thr == "0"
              result = {}
              t = 0
              result = Convert.to_map(
                SCR.Execute(
                  path(".target.bash_output"),
                  "grep processor /proc/cpuinfo | wc -l"
                )
              )
              t = Builtins.tointeger(Ops.get_string(result, "stdout", ""))
              t = 0 if t == nil
              UI.ChangeWidget(Id(:threads), :Value, Builtins.sformat("%1", t))
            end
            next
          end
        end

        if ret == :next || ret == :back
          val = ValidateSecurity()
          if val == true
            SaveSecurity()
            break
          else
            ret = nil
            next
          end
        end

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if Builtins.contains(@DIALOG, Convert.to_string(ret))
          ret = Builtins.symbolof(Builtins.toterm(ret))
          val = ValidateSecurity()
          if val == true
            SaveSecurity()
            break
          else
            ret = nil
            Wizard.SelectTreeItem("security")
            next
          end
        end

        Builtins.y2error("unexpected retcode: %1", ret)
      end
      deep_copy(ret)
    end

    def ValidateService
      true
    end

    def SaveServiceToConf
      if UI.QueryWidget(Id(:mgmtd), :Value) == true
        SCR.Write(path(".openais.pacemaker.use_mgmtd"), "yes")
      else
        SCR.Write(path(".openais.pacemaker.use_mgmtd"), "no")
      end

      nil
    end

    def SaveService
      Cluster.use_mgmtd = Convert.to_boolean(UI.QueryWidget(Id(:mgmtd), :Value))

      nil
    end

    def UpdateServiceStatus
      ret = 0
      ret = Service.Status("openais")
      if ret == 0
        UI.ChangeWidget(Id(:status), :Value, _("Running"))
      else
        UI.ChangeWidget(Id(:status), :Value, _("Not running"))
      end
      UI.ChangeWidget(Id("start_now"), :Enabled, ret != 0)
      UI.ChangeWidget(Id("stop_now"), :Enabled, ret == 0)

      result = {}
      result = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "/sbin/chkconfig openais 2>/dev/null | awk '{print $2}'"
        )
      )
      if Builtins.find(Ops.get_string(result, "stdout", ""), "off") != -1
        UI.ChangeWidget(Id("off"), :Value, true)
        UI.ChangeWidget(Id("on"), :Value, false)
      else
        UI.ChangeWidget(Id("on"), :Value, true)
        UI.ChangeWidget(Id("off"), :Value, false)
      end

      nil
    end

    def ServiceDialog
      ret = nil

      # map<string, any> firewall_widget = CWMFirewallInterfaces::CreateOpenFirewallWidget ($[
      # 		"services" : [ "port:5141" ],
      # 		"display_details" : true,
      # 		]);
      # term firewall_layout = firewall_widget["custom_widget"]:`VBox();

      contents = VBox(
        VSpacing(1),
        Frame(
          _("Booting"),
          RadioButtonGroup(
            Id("bootopenais"),
            HBox(
              HSpacing(1),
              VBox(
                Left(
                  RadioButton(
                    Id("on"),
                    Opt(:notify),
                    _("On -- Start openais at booting")
                  )
                ),
                Left(
                  RadioButton(
                    Id("off"),
                    Opt(:notify),
                    _("Off -- Start openais manually only")
                  )
                )
              )
            )
          )
        ),
        VSpacing(1),
        Frame(
          _("Switch On and Off"),
          Left(
            VBox(
              Left(
                HBox(
                  Label(_("Current Status: ")),
                  Label(Id(:status), _("Running")),
                  ReplacePoint(Id("status_rp"), Empty())
                )
              ),
              Left(
                HBox(
                  HSpacing(1),
                  HBox(
                    PushButton(Id("start_now"), _("Start openais Now")),
                    PushButton(Id("stop_now"), _("Stop openais Now"))
                  )
                )
              )
            )
          )
        ),
        VSpacing(1),
        Frame(
          _("Management Tool"),
          Left(
            HBox(
              HSpacing(1),
              CheckBox(
                Id(:mgmtd),
                "Enable mgmtd. The GUI client requires this.",
                true
              )
            )
          )
        ),
        VStretch()
      )


      my_SetContents("service", contents)

      UI.ChangeWidget(Id(:mgmtd), :Value, Cluster.use_mgmtd)

      while true
        UpdateServiceStatus()
        ret = UI.UserInput

        if ret == "on" || ret == "off"
          SCR.Execute(
            path(".target.bash"),
            Builtins.sformat("chkconfig openais %1", ret)
          )
          next
        end

        if ret == "start_now"
          Cluster.save_csync2_conf
          Cluster.SaveClusterConfig
          Report.Error(Service.Error) if !Service.Start("openais")
          next
        end

        if ret == "stop_now"
          Report.Error(Service.Error) if !Service.Stop("openais")
          next
        end

        if ret == :next || ret == :back
          val = ValidateService()
          if val == true
            SaveService()
            break
          else
            ret = nil
            next
          end
        end

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if Builtins.contains(@DIALOG, Convert.to_string(ret))
          ret = Builtins.symbolof(Builtins.toterm(ret))
          val = ValidateService()
          if val == true
            SaveService()
            break
          else
            ret = nil
            Wizard.SelectTreeItem("service")
            next
          end
        end

        Builtins.y2error("unexpected retcode: %1", ret)
      end
      deep_copy(ret)
    end


    def csync2_layout
      VBox(
        Opt(:hvstretch),
        HBox(
          Frame(
            _("Sync Host"),
            VBox(
              SelectionBox(Id(:host_box), ""),
              HBox(
                PushButton(Id(:host_add), _("Add")),
                PushButton(Id(:host_del), _("Del")),
                PushButton(Id(:host_edit), _("Edit"))
              )
            )
          ),
          HSpacing(),
          Frame(
            _("Sync File"),
            VBox(
              SelectionBox(Id(:include_box), ""),
              HBox(
                PushButton(Id(:include_add), _("Add")),
                PushButton(Id(:include_del), _("Del")),
                PushButton(Id(:include_edit), _("Edit")),
                PushButton(Id(:include_suggest), _("Add Suggested Files"))
              )
            )
          )
        ),
        HBox(
          PushButton(
            Id(:generate_key),
            Opt(:hstretch),
            _("Generate Pre-Shared-Keys")
          ),
          PushButton(Id(:csync2_switch), Opt(:hstretch), "")
        )
      )
    end


    # return 1 if csync2 is not installed well
    # return 2 if csync2 is OFF
    # return 3 if csync2 is ON
    def csync2_status
      ret = nil

      ret = Convert.to_map(
        SCR.Execute(path(".target.bash_output"), "/sbin/chkconfig csync2")
      )
      Builtins.y2milestone("chkconfig csync2 = %1", ret)
      if Builtins.issubstring(
          Ops.get_string(ret, "stderr", ""),
          "command not found"
        ) == true
        return 1
      end
      if Builtins.issubstring(
          Ops.get_string(ret, "stderr", ""),
          "unknown service"
        ) == true
        return 1
      end
      if Builtins.issubstring(Ops.get_string(ret, "stdout", ""), "off") == true
        return 2
      end

      3
    end

    def try_restart_xinetd
      r = Service.RunInitScript("xinetd", "try-restart")
      Builtins.y2debug("try_restart_xinetd return %1", r)
      r
    end

    def csync2_turn_off
      SCR.Execute(path(".target.bash_output"), "/sbin/chkconfig csync2 off")
      if SuSEFirewall.HaveService(@csync2_port, "TCP", "EXT")
        SuSEFirewall.RemoveService(@csync2_port, "TCP", "EXT")
      end
      try_restart_xinetd

      nil
    end

    def csync2_turn_on
      SCR.Execute(path(".target.bash_output"), "/sbin/chkconfig csync2 on")
      if !SuSEFirewall.HaveService(@csync2_port, "TCP", "EXT")
        SuSEFirewall.AddService(@csync2_port, "TCP", "EXT")
      end
      try_restart_xinetd

      nil
    end

    def fill_csync_entries
      i = 0
      ret = 0
      current = 0
      items = []

      # remove duplicated elements
      Cluster.csync2_host = Ops.add(Cluster.csync2_host, [])
      Cluster.csync2_include = Ops.add(Cluster.csync2_include, [])

      i = 0
      items = []
      Builtins.foreach(Cluster.csync2_host) do |value|
        items = Builtins.add(items, Item(Id(i), value))
        i = Ops.add(i, 1)
      end
      current = Convert.to_integer(UI.QueryWidget(:host_box, :CurrentItem))
      current = 0 if current == nil
      current = Ops.subtract(i, 1) if Ops.greater_or_equal(current, i)
      UI.ChangeWidget(:host_box, :Items, items)
      UI.ChangeWidget(:host_box, :CurrentItem, current)

      i = 0
      items = []
      Builtins.foreach(Cluster.csync2_include) do |value|
        items = Builtins.add(items, Item(Id(i), value))
        i = Ops.add(i, 1)
      end
      current = Convert.to_integer(UI.QueryWidget(:include_box, :CurrentItem))
      current = 0 if current == nil
      current = Ops.subtract(i, 1) if Ops.greater_or_equal(current, i)
      UI.ChangeWidget(:include_box, :Items, items)
      UI.ChangeWidget(:include_box, :CurrentItem, current)

      ret = csync2_status
      UI.ChangeWidget(Id(:csync2_switch), :Enabled, ret != 1)
      if ret == 1
        UI.ChangeWidget(Id(:csync2_switch), :Label, _("Csync2 Status Unknown"))
      end
      if ret == 2
        UI.ChangeWidget(Id(:csync2_switch), :Label, _("Turn csync2 ON"))
      end
      if ret == 3
        UI.ChangeWidget(Id(:csync2_switch), :Label, _("Turn csync2 OFF"))
      end

      nil
    end


    def Csync2Dialog
      ret = nil

      my_SetContents("csync2", csync2_layout)


      while true
        fill_csync_entries

        ret = UI.UserInput

        if ret == :abort || ret == :cancel
          break if ReallyAbort()
          next
        end

        break if ret == :next || ret == :back

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if Builtins.contains(@DIALOG, Convert.to_string(ret))
          ret = Builtins.symbolof(Builtins.toterm(ret))
          #SaveCsync2();
          break
        else
          Wizard.SelectTreeItem("csync2")
          next
        end

        if ret == :host_add
          ret = text_input_dialog(_("Enter a hostname"), "")
          next if ret == :cancel
          Cluster.csync2_host = Builtins.add(
            Cluster.csync2_host,
            Convert.to_string(ret)
          )
        end

        if ret == :host_edit
          current = 0
          str = ""

          current = Convert.to_integer(UI.QueryWidget(:host_box, :CurrentItem))
          ret = text_input_dialog(
            _("Edit the hostname"),
            Ops.get(Cluster.csync2_host, current, "")
          )
          next if ret == :cancel
          Ops.set(Cluster.csync2_host, current, Convert.to_string(ret))
        end

        if ret == :host_del
          current = 0
          current = Convert.to_integer(UI.QueryWidget(:host_box, :CurrentItem))
          Cluster.csync2_host = Builtins.remove(Cluster.csync2_host, current)
        end

        if ret == :include_add
          ret = text_input_dialog(_("Enter a filename to synchronize"), "")
          next if ret == :cancel
          Cluster.csync2_include = Builtins.add(
            Cluster.csync2_include,
            Convert.to_string(ret)
          )
        end

        if ret == :include_edit
          current = 0

          current = Convert.to_integer(
            UI.QueryWidget(:include_box, :CurrentItem)
          )
          ret = text_input_dialog(
            _("Edit the filename"),
            Ops.get(Cluster.csync2_include, current, "")
          )
          next if ret == :cancel
          Ops.set(Cluster.csync2_include, current, Convert.to_string(ret))
        end

        if ret == :include_del
          current = 0
          current = Convert.to_integer(
            UI.QueryWidget(:include_box, :CurrentItem)
          )
          Cluster.csync2_include = Builtins.remove(
            Cluster.csync2_include,
            current
          )
        end

        if ret == :include_suggest
          Cluster.csync2_include = Ops.add(
            Cluster.csync2_include,
            @csync2_suggest_files
          )
        end

        if ret == :generate_key
          key_file = Cluster.csync2_key_file

          # key file exist
          if Ops.greater_than(SCR.Read(path(".target.size"), key_file), 0)
            if !Popup.YesNo(
                Builtins.sformat(
                  _("Key file %1 already exist.\nDo you want to overwrite it?"),
                  key_file
                )
              )
              next
            end

            # remove exist key file
            if SCR.Execute(path(".target.remove"), key_file) == false
              Popup.Message(
                Builtins.sformat(_("Delete key file %1 failed."), key_file)
              )
              next
            end
          end

          # generate key file
          ret = SCR.Execute(
            path(".target.bash"),
            Builtins.sformat("csync2 -k %1", key_file)
          )
          if ret == 0
            Popup.Message(
              Builtins.sformat(
                _(
                  "Key file %1 is generated.\nClicking \"Add Suggested Files\" button adds it to sync list."
                ),
                key_file
              )
            )
          else
            Popup.Message(_("Key generation failed."))
          end
        end

        if ret == :csync2_switch
          label = ""
          label = Convert.to_string(UI.QueryWidget(:csync2_switch, :Label))
          csync2_turn_off if Builtins.issubstring(label, "OFF")
          csync2_turn_on if Builtins.issubstring(label, "ON")
        end
      end

      deep_copy(ret)
    end
  end
end
