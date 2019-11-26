#!/usr/bin/perl --
use strict;
use warnings;
use utf8;

# mastodonのdockerコンテナの rails console はreadline がUS-ASCIIなので、文字列リテラルはエスケープが必要
sub escapeNonAscii($){
    my($a) = @_;
    $a =~ s/([\x{80}-\x{fffff}])/"\\u{".sprintf("%x",ord $1)."}"/ge;
    $a;
}

my $phrase = escapeNonAscii quotemeta 'めったにPawooを使いません';

# rails console に送るコマンドはワンライナーにする必要がある
my $cmd = <<"END";
Account
    .where(domain:'pawoo.net',suspended_at:nil)
    .where('note like ?',"%$phrase%")
    .map{ |account|
    SuspendAccountService.new.call(account, reserve_email: false)
    ;"#{account.username},#{account.domain}"
}
END

# ワンライナーを整形する
$cmd =~ s/^\s*#.+/ /gm;
$cmd =~ s/[\s\x0d\x0a]+/ /g;

# ワンライナーをrails console に送る
open(my $fh,"|-","bundle exec rails console") or die $!;
print $fh $cmd;
close($fh) or die $!;
