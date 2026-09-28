{{/*
Validate CIDRs without DNS lookup. Host bits are accepted, as with Go net.ParseCIDR.
Test names below refer to tests/ip_allowlist_test.yaml. Each cited systemCIDRs
case also has a userCIDRs counterpart exercising the same validation path.
*/}}
{{- define "wandb.ipAllowList.validCIDR" -}}
  {{/*
  Four decimal octets, each 0-255, without leading zeros.
  Tests: "accepts systemCIDRs 255.255.255.255/32",
  "rejects systemCIDRs '256.1.1.1/32'",
  "rejects systemCIDRs '192.00.2.1/24'",
  "rejects systemCIDRs '192.0.2/24'".
  */}}
  {{- $octet := "(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])" -}}
  {{- $ipv4 := printf "%s(\\.%s){3}" $octet $octet -}}
  {{- $parts := splitList "/" . -}}
  {{- $valid := false -}}
  {{/*
  Require exactly one slash separating address and prefix.
  Tests: "accepts systemCIDRs 192.0.2.5/24",
  "rejects systemCIDRs '192.0.2.1'",
  "rejects systemCIDRs '192.0.2.1/8/1'".
  */}}
  {{- if eq (len $parts) 2 -}}
    {{- $address := index $parts 0 -}}
    {{- $prefix := index $parts 1 -}}
    {{/*
    Require decimal prefix digits before numeric conversion; no signs or whitespace.
    Tests: "accepts systemCIDRs 192.0.2.1/08",
    "rejects systemCIDRs '192.0.2.1/-1'",
    "rejects systemCIDRs '192.0.2.1/+1'",
    "rejects systemCIDRs '192.0.2.1/24 '".
    */}}
    {{- if regexMatch "^[0-9]{1,3}$" $prefix -}}
      {{/*
      A colon selects IPv6 validation; otherwise use IPv4 validation below.
      Tests: "accepts systemCIDRs 2001:db8::/32", "accepts systemCIDRs 192.0.2.5/24".
      */}}
      {{- if contains ":" $address -}}
        {{/*
        An IPv4 tail occupies two IPv6 groups. Validate it before replacing it.
        Tests: "accepts systemCIDRs ::ffff:192.0.2.1/128",
        "accepts systemCIDRs 1:2:3:4:5:6:192.0.2.1/96",
        "rejects systemCIDRs '::ffff:256.1.1.1/128'",
        "rejects systemCIDRs '::ffff:192.00.2.1/128'",
        "rejects systemCIDRs '1:2:3:4:5:6:7:192.0.2.1/128'",
        "rejects systemCIDRs '192.0.2.1::/64'".
        */}}
        {{- $tail := last (splitList ":" $address) -}}
        {{- $tailValid := true -}}
        {{- if contains "." $address -}}
          {{- $tailValid = regexMatch (printf "^%s$" $ipv4) $tail -}}
          {{- $address = printf "%s0:0" (trimSuffix $tail $address) -}}
        {{- end -}}
        {{- $compressed := contains "::" $address -}}
        {{- $groups := splitList ":" $address | compact -}}
        {{/*
        Preserve tail validation and limit IPv6 prefixes to 128, parsing in decimal.
        Tests: "accepts systemCIDRs ::/0", "accepts systemCIDRs ::1/128",
        "rejects systemCIDRs '::/129'",
        "rejects systemCIDRs '::ffff:256.1.1.1/128'".
        */}}
        {{- $valid = and $tailValid (le (atoi $prefix) 128) -}}
        {{/*
        Every nonempty group must contain only hexadecimal digits; retain earlier failures.
        Tests: "accepts systemCIDRs 2001:DB8:0:0:0:0:0:1/128",
        "rejects systemCIDRs '2001:db8::g/64'",
        "rejects systemCIDRs 'fe80::1%eth0/64'",
        "rejects systemCIDRs '[::1]/128'".
        */}}
        {{- range $groups -}}
          {{- $valid = and $valid (regexMatch "^[0-9a-fA-F]{1,4}$" .) -}}
        {{- end -}}
        {{/*
        Compression must omit at least one group, occur once, and use exactly two colons.
        Tests: "accepts systemCIDRs ::/0", "accepts systemCIDRs 1:2:3:4:5:6:7::/127",
        "rejects systemCIDRs '1:2:3:4:5:6:7:8::/64'" (group count),
        "rejects systemCIDRs '1::2::3/64'" (multiple compressions),
        "rejects systemCIDRs ':::/64'" (triple colon).
        */}}
        {{- if $compressed -}}
          {{- $valid = and $valid (lt (len $groups) 8) (eq (len (splitList "::" $address)) 2) (not (contains ":::" $address)) -}}
        {{- else -}}
          {{/*
          Uncompressed IPv6 requires exactly eight groups.
          Tests: "accepts systemCIDRs 2001:DB8:0:0:0:0:0:1/128",
          "rejects systemCIDRs '1:2:3:4:5:6:7/64'",
          "rejects systemCIDRs '1:2:3:4:5:6:7:8:9/64'".
          */}}
          {{- $valid = and $valid (eq (len $groups) 8) -}}
        {{- end -}}
        {{/*
        A single leading/trailing colon is never valid, even with compression elsewhere.
        Tests: "rejects systemCIDRs ':1:2:3:4:5:6:7:8/64'" (leading),
        "rejects systemCIDRs '1::2:/64'" (trailing),
        "accepts systemCIDRs ::1/128", "accepts systemCIDRs 1:2:3:4:5:6:7::/127".
        */}}
        {{- $badEdge := or (and (hasPrefix ":" $address) (not (hasPrefix "::" $address))) (and (hasSuffix ":" $address) (not (hasSuffix "::" $address))) -}}
        {{- $valid = and $valid (not $badEdge) -}}
      {{- else -}}
        {{/*
        Require a valid IPv4 address and prefix at most 32; host bits are allowed.
        Tests: "accepts systemCIDRs 0.0.0.0/0", "accepts systemCIDRs 255.255.255.255/32",
        "accepts systemCIDRs 192.0.2.5/24", "accepts systemCIDRs 192.0.2.1/08",
        "rejects systemCIDRs '192.0.2.1/33'",
        "rejects systemCIDRs 'example.com/24'".
        */}}
        {{- $valid = and (regexMatch (printf "^%s$" $ipv4) $address) (le (atoi $prefix) 32) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{/*
  Only successful validation emits "true"; the caller fails rendering otherwise.
  Tests: "accepts systemCIDRs ::1/128", "rejects systemCIDRs '::/129'".
  */}}
  {{- if $valid -}}true{{- end -}}
{{- end -}}

{{- define "wandb.ipAllowList.sourceRanges" -}}
  {{- concat .Values.global.ipAllowList.systemCIDRs .Values.global.ipAllowList.userCIDRs | uniq | toYaml -}}
{{- end -}}
