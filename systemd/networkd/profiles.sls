# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "systemd/map.jinja" import systemd with context %}
{%- set networkd = systemd.get('networkd', {}) %}
{%- set profiles = networkd.get('profiles', {}) %}

{%- if networkd.networkctl_reload %}
include:
  - systemd.networkd.reload
{%- endif %}

{%- if profiles is mapping %}
{%- for networkdprofile, types in profiles.items()  %}
  {%- for profile, profileconfig in types.items() %}
  {%- set filename = profile ~ "." ~ networkdprofile %}
  {%- set user = networkd.fileattr.get(filename, {}).user | default("root") %}
  {%- set group = networkd.fileattr.get(filename, {}).group | default("root") %}
  {%- set mode = networkd.fileattr.get(filename, {}).mode | default("0644") %}

/etc/systemd/network/{{ filename }}:
  file.managed:
    - template: jinja
    - source: salt://systemd/networkd/templates/profile.jinja
    - user: {{ user }}
    - group: {{ group }}
    - mode: {{ mode }}
    - makedirs: true
    - dir_mode: 755
    - context:
        config: {{ profileconfig|json }}
{%- if networkd.networkctl_reload %}
    - watch_in:
      - cmd: systemd-networkd-reload-cmd-wait
{%- endif %}
  {%- endfor %}
{%- endfor %}
{%- endif %}
