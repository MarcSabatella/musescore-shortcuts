#!/usr/bin/perl
use strict;
use warnings;

my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";

my $arg1 = $ARGV[1] or die "Please specify 'full' or 'common'\n";
my $fullTable = ($arg1 eq "full");

open(my $data, '<', $file) or die "Could not open '$file' $!\n";

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub formatKeys {
  my $field = trim $_[0];
  my @formatKeys;
  my @shortcutRange = split " - ", $field;
  for my $i (0 .. $#shortcutRange) {
    my $shortcutItem = trim($shortcutRange[$i]);
    my @rawKeys = split "\\+" , $shortcutItem;
    $formatKeys[$i] = join "", "<kbd><kbd>", join("</kbd>+<kbd>", @rawKeys), "</kbd></kbd>";
    $formatKeys[$i] =~ s/\&plus;/+/g;
  }

  return join " &ndash; ", @formatKeys;
};

my $inTable = 0;

while (my $rawLine = <$data>) {

  my $line = $rawLine;
  chomp $line;

  # parse line

  if (substr($line, 0, 1) eq "*") {

    # line not "important"

    if (!$fullTable) {
      next;
    }
    $line = substr($line, 1);

  }

  if (!length $line) {

    # this line is empty

    print "\n";
    next;

  }

  my @fields = split(", " , $line);

  if (scalar @fields == 1) {

    # this line is plain text

    $line =~ s/\&comma;/,/g;

    if ($inTable) {

      # leave table

      $inTable = 0;

    }

    if (substr($line, 0, 1) eq "#") {

      # markdown heading

      print $line;

      # add anchor info (non-standard)
      #my $anchor = lc $line;
      #$anchor =~ s/#+ //;
      #$anchor =~ s/[,.;\'\"\!\\\/]//g;
      #$anchor =~ s/ /-/g;
      #print " {#", $anchor, "}";

      print "\n";

    } else {

      # other text

      print $line, "\n";

    }

  } else {

    # this line is a command

    if (!$inTable) {

      # generate headings

      # headings for combined shortcut columns
      #print "Action | Shortcut\n---|---\n";
      # headings for separate shortcut columns
      print "Action | Windows/Linux | macOS\n---|---|---\n";

      $inTable = 1;

    }

    my $command = trim($fields[0]);

    my $shortcut = trim($fields[1]);
    my $formatKeysRange = formatKeys($shortcut);
    my $formatKeysRangeMac = "";
    if (scalar @fields == 2) {

      # no explicit macOS shortcut given; try to derive automatically

      my $shortcutMac = $shortcut;
      $shortcutMac =~ s/Ctrl/Cmd/g;
      $shortcutMac =~ s/Alt/Option/g;
      $shortcutMac =~ s/F\d+/Fn+$&/g;
      $shortcutMac =~ s/Home/Fn+Left/g;
      $shortcutMac =~ s/End/Fn+Right/g;
      $shortcutMac =~ s/PgUp/Fn+Up/g;
      $shortcutMac =~ s/PgDn/Fn+Down/g;
      #if ($shortcut ne $shortcutMac) {
        $formatKeysRangeMac = formatKeys($shortcutMac);
      #}

    } else {

      # use explicit macOS shortcut

      $formatKeysRangeMac = formatKeys($fields[2]);
    }

    # create final output

    my $outputFormatCombined = "%s | %s\n";
    my $outputFormatSeparate = "%s | %s | %s\n";

    my $formatKeysRangeCombo = $formatKeysRange;
    if ($formatKeysRangeMac) {
      $formatKeysRangeCombo = join "", $formatKeysRangeCombo, " (macOS: ", $formatKeysRangeMac, ")";
    }

    # show shortcuts for Windows/Linux and macOS combined in one column
    #printf $outputFormatCombined, $command, $formatKeysCombo;

    # show shortcuts for Windows/Linux and macOS in separate columns
    printf $outputFormatSeparate, $command, $formatKeysRange, $formatKeysRangeMac;

  }

}
