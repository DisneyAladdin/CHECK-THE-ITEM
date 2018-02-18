#!/usr/bin/env perl
# This program was created by Kawabata Shuto and all copyrights have been saved  on August 15th, 2017.
# shuto kawabata, University of Tsukuba, Tochigi prefecture, Utsunomiya city.
use utf8;
use Encode;
use strict;
use warnings;
use URI::Escape; #for encoding string
use Time::HiRes qw(sleep); #for sleep
use LWP::Simple; # get html
use LWP::UserAgent; # get html as UserAgent
use Mozilla::CA; #get html as Mozilla browser 
use Term::ANSIColor qw(:constants); #for print with color
$Term::ANSIColor::AUTORESET = 1;
use Term::ANSIColor 2.00 qw(:pushpop);
# for E-mail
use Authen::SASL;
use MIME::Base64;
use Net::SMTP;
use Data::Dumper;
use Math::Round;
use Proc::CPUUsage;





my $q = 0;
while ($q == 0){
#print "Sleeping...zZ\n";
#sleep(5);
my $num = 1;
open(F, "item_list.csv")||die "cannot open 'item_list.csv':$!\n";
while(my $list = <F>){
	my $cpu = Proc::CPUUsage->new;
    	my $usage1 = $cpu->usage; ## returns usage since new()
    	my $usage2 = $cpu->usage; ## returns usage since last usage()
#	print $usage1."\n";
#	print $usage2."\n";

	# Extract domain
	my @rec   = split(/,/,$list);
	my $url   = $rec[0];
	my $iName = $rec[2];
	my $limit = $rec[1];
	chomp($iName);
	my $domin;
	if ($url =~ /^(http|https):\/\/([-\w\.]+)\//){
		$domin = $1."://".$2;
	}
	# Obtain html
	print "ID: $num";
	print "\n";                                           
	print "Now getting html ...\n";
	sleep(0.1);
	my $html = get($url) or die "The web-page of $url does not exsist. So, please remove $url of $num from item_list.csv ";

	if($domin eq 'http://www.biccamera.com'){
		&Big_Camera($num,$html,$url,$iName,$domin,$limit);
	}elsif($domin eq 'http://www.yodobashi.com'){
		&Yodobashi($num,$html,$url,$iName,$domin,$limit);
	}elsif($domin eq 'http://shop.tsutaya.co.jp'){
		&TSUTAYA($num,$html,$url,$iName,$domin,$limit);
	}elsif($domin eq 'https://www.amazon.co.jp'){
		&Amazon;
	}elsif($domin eq 'https://online.nojima.co.jp'){
		&Nojima($num,$url,$iName,$domin,$limit);
	}elsif($domin eq 'http://www.yamada-denkiweb.com'){
		&Yamada($num,$html,$url,$iName,$domin,$limit);
	}elsif($domin eq 'https://item.mercari.com'){
		&mercari($num,$html,$url,$iName,$domin,$limit);
	}elsif($domin eq 'http://7net.omni7.jp'){
		&omuni7($num,$html,$url,$iName,$domin,$limit);
	}elsif($domin eq 'https://item.rakuten.co.jp'){
		&rakuten($num,$html,$url,$iName,$domin,$limit);
	}elsif($domin eq 'http://www.ksdenki.com'){
		&ksdenki($num,$html,$url,$iName,$domin,$limit);
	}elsif($domin eq 'http://www.sofmap.com'){
		&sofmap($num,$html,$url,$iName,$domin,$limit); 
	}elsif($domin eq 'http://www.kojima.net'){
		&kojima($num,$html,$url,$iName,$domin,$limit);
	}
	print "\n\n";
	$num++;
}
close(F);
}





sub Notify{
	my $name  = shift;
	my $price = shift;
	my $url   = shift;
	my $store = shift;

	my $min_list_price  = shift;
	my $min_list_url    = shift;
	my $iName           = shift;
	my $num             = shift;
	my $min_list_domoin = shift;
	my $min_list_num    = shift;
	my $deduction       = shift;
	my $time            = shift;
	my $status_jpn      = shift;
	my $NID             = shift;
	my $limit           = shift;
	#Alerm
	print "\007";

	#display notification on macbook
	my $cmd= <<EOL;
osascript -e 'display notification "在庫を確認しました" with title "お知らせ" subtitle "$name"'
EOL
  	my $a=`$cmd`;
  	print "$a";


	#send E-mail

my $SMTP_CONF =
    {host=> 'smtp.mail.yahoo.co.jp', #yahooのsmtpサーバを送信用に指定
     port=> '587',
     from=> 'Username@yahoo.co.jp', #送信用メールアドレスを入力
     return_path=> 'Username@yahoo.co.jp', #上に同じ
     auth_uid=> 'Username@yahoo.co.jp', #上に同じ
     auth_pw=> 'password' #Yahooアカウントのパスワード

    };

main($name,$price,$url,$store,$min_list_price,$min_list_url,$iName,$num,$min_list_domoin,$min_list_num,$deduction,$time,$status_jpn,$NID,$limit);

sub main {
	my $name  = shift;
	my $price = shift;
	my $url   = shift;
	my $store = shift;
	my $min_list_price = shift;
	my $min_list_url   = shift;
	my $iName          = shift;
	my $num            = shift;
	my $min_list_domoin= shift;
	my $min_list_num   = shift;
	my $deduction      = shift;
	my $time           = shift;
	my $status_jpn     = shift;
	my $NID            = shift;
	my $limit          = shift;
	#以下のAcceptを替えて受信先のアドレスとして指定してください.
	publish_test_mail(['Accept@gmail.com'],$name,$price,$url,$store,$min_list_price,$min_list_url,$iName,$num,$min_list_domoin,$min_list_num,$deduction,$time,$status_jpn,$NID,$limit);
}



sub publish_test_mail {
	my ($mailto ) = shift; #default
#	my($mailto ) = shift;
	my $name     = shift;
	my $price    = shift;
	my $url      = shift;
	my $store    = shift;
	my $min_list_price = shift;
	my $min_list_url   = shift;
	my $iName          = shift;
 	my $num            = shift;
	my $min_list_domin = shift;
	my $min_list_num   = shift;
	my $deduction      = shift;
	my $time           = shift;
	my $status_jpn     = shift;
	my $NID            = shift;
	my $limit          = shift;
	my $subject_org = '在庫を確認しました';
	my $subject = Encode::encode('MIME-Header-ISO_2022_JP', $subject_org);

	my $display_deduction = abs($deduction);

	if($min_list_domin eq 'http://www.biccamera.com'){
		$min_list_domin = 'ビックカメラ';
	}elsif($min_list_domin eq 'http://www.yodobashi.com'){
		$min_list_domin = 'ヨドバシカメラ';
	}elsif($min_list_domin eq 'http://shop.tsutaya.co.jp'){
		$min_list_domin = 'TSUTAYAオンライン';
	}elsif($min_list_domin eq 'https://online.nojima.co.jp'){
		$min_list_domin = 'ノジマ電気';
	}elsif($min_list_domin eq 'http://www.yamada-denkiweb.com'){
		$min_list_domin = 'ヤマダ電機';
	}elsif($min_list_domin eq 'https://item.mercari.com'){
		$min_list_domin = 'メルカリ';
	}elsif($min_list_domin eq 'http://7net.omni7.jp'){
		$min_list_domin = 'オムニ７';
	}elsif($min_list_domin eq 'https://item.rakuten.co.jp'){
		$min_list_domin = '楽天オンライン';
	}elsif($min_list_domin eq 'http://www.ksdenki.com'){
		$min_list_domin = 'ケーズデンキ';
	}elsif($min_list_domin eq 'http://www.sofmap.com'){
		$min_list_domin = 'ソフマップ';
	}elsif($min_list_domin eq 'http://www.kojima.net'){
		$min_list_domin = 'コジマ';
	}

    #mailtoがない場合、送信は行いません. for debug                                                                                        
    	if( ref($mailto) ne "ARRAY" or @$mailto < 1 ){
        	return undef;
    	}
    	my $mailto_str = join(',', @$mailto );
    	my $message =<<EOF;
Hello, Shuto !
This E-mail was sent from the stock notification system since you added "$name" in item list as a favorite item and we confirmed that it is in stock now. Otherwise, status of the item or price of the item is now chenged.   
So, please check it below.
--------------------------------------------------------------------------
                    Title: Notification of $NID
--------------------------------------------------------------------------
【ID】: $num
【NAME】: $name
【CATEGORY】: $iName
【STORE】: $store
【PRICE】 :￥$price
【STATUS】: $status_jpn
【URL】 : $url
【LIMITER】:￥$limit
【TIME】: $time

--------------------------------------------------------------------------
The Lowest Price of【$iName】below.

【ID】: $min_list_num
【CATEGORY】: $iName
【STORE】: $min_list_domin
【PRICE】: ￥$min_list_price
【URL】: $min_list_url

--------------------------------------------------------------------------
The Lowest Price is presently calculated by ranking just each raw prices on real time. So, if you want to switch to another calculated by real price, which is sum of raw price and tax and point reduction, please tell us with no hesitation. This stock notification system has been created by 'Shuto Kawabata' in August, 2017. All Copyrights have been reserved since 2017.


EOF

    #メールのヘッダーを構築                                                                                                               
    my $header = << "MAILHEADER_1";
From: $SMTP_CONF->{from}
Return-path: $SMTP_CONF->{return_path}
Reply-To: $SMTP_CONF->{return_path}
To: $mailto_str
MAILHEADER_1

    $header .=<<"MAILHEADER_2";
Subject: $subject
Mime-Version: 1.0
Content-Type: text/plain; charset = "ISO-2022-JP"
Content-Transfer-Encoding: 7bit
MAILHEADER_2
    $message = encode('iso-2022-jp',$message);
    my $smtp = Net::SMTP->new($SMTP_CONF->{host},
                              Hello=>$SMTP_CONF->{host},
                              Port=> $SMTP_CONF->{port},
                              Timeout=>20,
#                              Debug=>   1                                                                                                
                             );
    unless($smtp){
        my $msg = "can't connect smtp server: $!";
        die $msg;
    }



    $smtp->auth($SMTP_CONF->{auth_uid}, $SMTP_CONF->{auth_pw}) or
        die "can't login smtp server";

    $smtp->mail($SMTP_CONF->{from});
    $smtp->to(@$mailto);
    $smtp->data();
    $smtp->datasend("$header\n");
    $smtp->datasend("$message\n");
    $smtp->dataend();
    $smtp->quit;
}

}





# コジマ
sub kojima{
	my $num  = shift;
	my $html = shift;
	my $url  = shift;
	my $iName= shift;
	my $domin= shift;
	my $limit= shift;
	my $store= 'コジマ';
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW encode('utf-8','コジマ')."\n";

	#name
	my $n1 = '<title>【コジマネット】';
	my $n2 = '</title>';
	$html =~ /$n1(.+)$n2/;
	 my $n3 = $+;
         my @n4 = split(/</,$n3,2);
         my $name = $n4[0];
         print "[NAME]:";
         print encode('utf-8',$name)."\n";
 
         #Price
	 $html =~ s/[\s　]+//g;
         my $m1 = '<spanclass="price">';
         my $m2 = '</span>';
         #$html =~ /$m1(.+)$m2/;
         #my $m3 = $+;
         my @line  = split(/$m1/,$html,2);
         my $m3    = $line[1];
	 my @line2 = split(/$m2/,$m3,2);
	 my $Price = $line2[0];
         $Price = &split_price($Price);
         # (row price, tax_id, percentage of point) 
         my $RP = &RP($Price,0,5);
 
         print "[PRICE]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA encode('utf-8',$Price);
         print " excluding tax.\n";
         print "[RealPrice]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA round($RP)."\n";

	#Inventory
         $html =~ s/[\s　]+//g;
         my $status;
         my $i1 = 'カートに入れる';
         if ($html =~ $i1){
                 $status = 0;
                 print "[STATUS]:";
                 print BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }else{
                 $status = 8;
                 print "[STATUS]:";
                 print BOLD RED encode('utf-8','在庫なし')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }
}









# ソフマップ
sub sofmap{
	my $num  = shift;
	my $html = shift;
	my $url  = shift;
	my $iName= shift;
	my $domin= shift;
	my $limit= shift;
	my $store= 'ソフマップ';
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW encode('utf-8','ソフマップ')."\n";

	#name
	my $n1 = '<span class="product-detail-name">';
	my $n2 = '</span>';
	$html =~ /$n1(.+)$n2/;
	 my $n3 = $+;
         my @n4 = split(/</,$n3,2);
         my $name = $n4[0];
         print "[NAME]:";
         print encode('utf-8',$name)."\n";
 
         #Price
         my $m1 = '<span class="product-detail-price2">&yen;';
         my $m2 = '</span>';
         $html =~ /$m1(.+)$m2/;
         my $m3 = $+;
         my @line = split(/</,$m3,2);
         my $Price = $line[0];
         $Price = &split_price($Price);
         # (row price, tax_id, percentage of point) 
         my $RP = &RP($Price,1,10);
 
         print "[PRICE]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA encode('utf-8',$Price);
         print " excluding tax.\n";
         print "[RealPrice]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA round($RP)."\n";

	#Inventory
         $html =~ s/[\s　]+//g;
         my $status;
         my $i1 = '<inputalt="カートに入れる"';
         if ($html =~ $i1){
                 $status = 0;
                 print "[STATUS]:";
                 print BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }else{
                 $status = 8;
                 print "[STATUS]:";
                 print BOLD RED encode('utf-8','在庫なし')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }
}






# ケーズデンキ
sub ksdenki{
	my $num  = shift;
	my $html = shift;
	my $url  = shift;
	my $iName= shift;
	my $domin= shift;
	my $limit= shift;
	my $store= 'ケーズデンキ';
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW encode('utf-8','ケーズデンキ')."\n";

	#name
	my $n1 = '<title>';
	my $n2 = '</title>';
	$html =~ /$n1(.+)$n2/;
	 my $n3 = $+;
         my @n4 = split(/</,$n3,2);
         my $name = $n4[0];
         print "[NAME]:";
         print encode('utf-8',$name)."\n";
 
         #Price
         my $m1 = '<span class="carousel_list_price_">';
         my $m2 = '円';
         $html =~ /$m1(.+)$m2/;
         my $m3 = $+;
         my @line = split(/円/,$m3,2);
         my $Price = $line[0];
         $Price = &split_price($Price);
         # (row price, tax_id, percentage of point) 
         my $RP = &RP($Price,1,5);
 
         print "[PRICE]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA encode('utf-8',$Price);
         print " excluding tax.\n";
         print "[RealPrice]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA round($RP)."\n";

	#Inventory
         $html =~ s/[\s　]+//g;
         my $status;
         my $i1 = 'カートに入れる';
         if ($html =~ $i1){
                 $status = 0;
                 print "[STATUS]:";
                 print BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }else{
                 $status = 8;
                 print "[STATUS]:";
                 print BOLD RED encode('utf-8','在庫なし')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }
}


# 楽天オンライン
sub rakuten{
	my $num  = shift;
	my $html = shift;
	my $url  = shift;
	my $iName= shift;
	my $domin= shift;
	my $limit= shift;
	my $store= '楽天オンライン';
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW encode('utf-8','楽天オンライン')."\n";

	#name
	my $n1 = '<title>【楽天市場】【送料無料】 ';
	my $n2 = '</title>';
	$html =~ /$n1(.+)$n2/;
	 my $n3 = $+;
         my @n4 = split(/</,$n3,2);
         my $name = $n4[0];
         print "[NAME]:";
         print encode('utf-8',$name)."\n";
 
         #Price
         my $m1 = '<span itemprop="price" content="';
         my $m2 = '" class="tax_postage">';
         $html =~ /$m1(.+)$m2/;
         my $m3 = $+;
         my @line = split(/"/,$m3,2);
         my $Price = $line[0];
         $Price = &split_price($Price);
         # (row price, tax_id, percentage of point) 
         my $RP = &RP($Price,0,1);
 
         print "[PRICE]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA encode('utf-8',$Price);
         print " excluding tax.\n";
         print "[RealPrice]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA round($RP)."\n";

	#Inventory
         $html =~ s/[\s　]+//g;
         my $status;
         my $i1 = '在庫有り';
         if ($html =~ $i1){
                 $status = 0;
                 print "[STATUS]:";
                 print BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }else{
                 $status = 8;
                 print "[STATUS]:";
                 print BOLD RED encode('utf-8','在庫なし')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }
}




# オムニ7
sub omuni7{
	my $num  = shift;
	my $html = shift;
	my $url  = shift;
	my $iName= shift;
	my $domin= shift;
	my $limit= shift;
	my $store= 'オムニ７';
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW encode('utf-8','オムニ７')."\n";

	#name
	my $n1 = '<title>オムニ7 - セブンネットショッピング｜';
	my $n2 = '通販</title>';
	$html =~ /$n1(.+)$n2/;
	 my $n3 = $+;
         my @n4 = split(/通販/,$n3,2);
         my $name = $n4[0];
         print "[NAME]:";
         print encode('utf-8',$name)."\n";
 
         #Price
         my $m1 = '"sale_price_num_notax": "';
         my $m2 = '円';
         $html =~ /$m1(.+)$m2/;
         my $m3 = $+;
         my @line = split(/円/,$m3,2);
         my $Price = $line[0];
         $Price = &split_price($Price);
         # (row price, tax_id, percentage of point) 
         my $RP = &RP($Price,1,1);
 
         print "[PRICE]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA encode('utf-8',$Price);
         print " excluding tax.\n";
         print "[RealPrice]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA round($RP)."\n";

	#Inventory
         $html =~ s/[\s　]+//g;
         my $status;
         my $i1 = 'カートに入れる';
         if ($html =~ $i1){
                 $status = 0;
                 print "[STATUS]:";
                 print BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }else{
                 $status = 8;
                 print "[STATUS]:";
                 print BOLD RED encode('utf-8','在庫なし')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }
}









# mercari
sub mercari{
	my $num  = shift;
	my $html = shift;
	my $url  = shift;
	my $iName= shift;
	my $domin= shift;
	my $limit= shift;
	my $store= 'mercari';
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW encode('utf-8','メルカリ')."\n";

	#name
	my $n1 = '<h2 class="item-name">';
	my $n2 = '</h2>';
	$html =~ /$n1(.+)$n2/;
	 my $n3 = $+;
         my @n4 = split(/</,$n3,2);
         my $name = $n4[0];
         print "[NAME]:";
         print encode('utf-8',$name)."\n";
 
         #Price
         my $m1 = '<span class="item-price bold">¥ ';
         my $m2 = '</span>';
         $html =~ /$m1(.+)$m2/;
         my $m3 = $+;
         my @line = split(/</,$m3,2);
         my $Price = $line[0];
         $Price = &split_price($Price);
         # (row price, tax_id, percentage of point) 
         my $RP = &RP($Price,0,0);
 
         print "[PRICE]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA encode('utf-8',$Price);
         print " excluding tax.\n";
         print "[RealPrice]:";
         print BOLD MAGENTA encode('utf-8','￥');
         print BOLD MAGENTA round($RP)."\n";

	#Inventory
         $html =~ s/[\s　]+//g;
         my $status;
         my $i1 = '購入ページへ';
         if ($html =~ $i1){
                 $status = 0;
                 print "[STATUS]:";
                 print BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }else{
                 $status = 8;
                 print "[STATUS]:";
                 print BOLD RED encode('utf-8','在庫なし')."\n";
                 &save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
         }
}



# YAMADA
sub Yamada{
	my $num  = shift;
	my $html = shift;
	my $url  = shift;
	my $iName = shift;
	my $domin = shift;
	my $limit = shift;
	my $store = 'ヤマダ電機';
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW encode('utf-8','ヤマダ電機')."\n";
	
	#Name
	my $n1 = '<meta property="og:title" content="';
	my $n2 = '"';
	$html =~ /$n1(.+)$n2/;
	my $n3 = $+;
	my @n4 = split(/ /,$n3,2);
	my $name = $n4[0];
	print "[NAME]:";
	print encode('utf-8',$name)."\n";

	#Price
	my $m1 = '<span class="highlight x-large">&yen;';
	my $m2 = '</span>';
	$html =~ /$m1(.+)$m2/;
	my $m3 = $+;
	my @line = split(/</,$m3,2);
	my $Price = $line[0];
	$Price = &split_price($Price);

	# (row price, tax_id, percentage of point) 
	my $RP = &RP($Price,1,1);

	print "[PRICE]:";
	print BOLD MAGENTA encode('utf-8','￥');
	print BOLD MAGENTA encode('utf-8',$Price);
	print " excluding tax.\n";
	print "[RealPrice]:";
	print BOLD MAGENTA encode('utf-8','￥');
	print BOLD MAGENTA round($RP)."\n";

	#Inventory
	$html =~ s/[\s　]+//g;
	my $status;
	my $i1 = 'カートに入れる';
	if ($html =~ $i1){
		$status = 0;
		print "[STATUS]:";
		print BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
		&save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
	}else{
		$status = 8;
		print "[STATUS]:";
		print BOLD RED encode('utf-8','在庫なし')."\n";
		&save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
	}
}




# Nojima
sub Nojima{
	my $num = shift;
	my $url = shift;
	my $iName = shift;
	my $domin = shift;
	my $limit = shift;
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW "ノジマ電気\n";
	my $store = 'ノジマ電気';
	
	# IE8のフリをする
	my $user_agent = "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)";
	# LWPを使ってサイトにアクセスし、HTMLの内容を取得する
	my $ua = LWP::UserAgent->new('agent' => $user_agent);
	my $res = $ua->get($url);
	my $content = $res->content;
	my $html = $content;
	my $htmls = $html;
	
	#Name
	$html =~ s/[\s　]+//g;
	print encode('utf-8','[STORE]:ノジマ電気')."\n";
	$html =~ /<h1class="shouhinhcommodityName"itemprop="name">(.+)</;
	my $st  = $+;
	my @str = split(/&/,$st,2);
	my $name = $str[0];
	print "[NAME]:";
	print $name."\n";

	#Price
        my $moji2 = encode('utf-8','円<span');
        $htmls =~ /<span class="pricenew">(.+)$moji2/; #<span class="pricenew">から円<spanまでの文字列（空白で区切れる)を抽出
        my $Price = $+;
	$Price = &split_price($Price);
	my $RP = &RP($Price,0,8);	

        print "[PRICE]:";
        print BOLD MAGENTA encode('utf-8','￥');
        print BOLD MAGENTA $Price;
        print " yen including tax.\n";
	print "[RealPrice]:";
	print BOLD MAGENTA encode('utf-8','￥');
	print BOLD MAGENTA round($RP)."\n";

	#Inventory
	my $status;
        my $moji = encode('utf-8','カートに入れる');
	if($htmls=~ $moji){
		$status = 0;
		print "[STATUS]:";
		print BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
		&save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
	}else{
		$status = 8;
		print "[STATUS]:";
		print BOLD RED encode('utf-8','在庫なし')."\n";
		&save_file($num,$name,$Price,$url,$store,$iName,$domin,$status,$RP,$limit);
	}

}





# TSUTAYA
sub TSUTAYA{
	my $num  = shift;
	my $html = shift;
	my $url  = shift;
	my $iName = shift;
	my $domin = shift;
	my $limit = shift;
	my $store = 'TSUTAYAオンライン';
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	# domain
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW encode('utf-8','TSUTAYAオンライン')."\n";

	# Name of item
	$html =~ /_sc.pageName = "商品詳細:(.+)"/;
	my $name = $+;
	print "[NAME]:";
 	print encode('utf-8',$name)."\n";
	
	# Price
        $html =~ /<li>価格（税込）：<span class="tolNote"><em class="nowrap">(.+)円/;
        my $price = $+;
	$price = &split_price($price);
	my $RP = &RP($price,0,0.5);

	print "[PRICE]:";
        print BOLD MAGENTA encode('utf-8','￥');
        print BOLD MAGENTA $price;
        print " including tax\n";
	print "[RealPrice]:";
	print BOLD MAGENTA encode('utf-8','￥');
	print BOLD MAGENTA round($RP)."\n";
	
	# Inventory
	my $status;
	$html =~ s/[\s　]+//g;#空白、タブ削除
	print "[STATUS]:";
	if ($html =~ /title="買い物かごへ"alt="買い物かごへ"/){
		print  BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
		$status =0;
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);

	}elsif($html =~ /<imgsrc="\/library\/img\/base\/ic\/btn_nostockL.png"alt="在庫なし"/){
		$status =8;
		print BOLD RED encode('utf-8','在庫なし')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
	}elsif($html =~ /title="買い物かごへ（予約）"/){
		$status =1;
		print BOLD BRIGHT_GREEN  encode('utf-8','予約受付中')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
	}elsif($html =~ /<p><spanclass="label_gray">完売しました<\/span><\/p>/){
		$status =9;
		print BOLD RED encode('utf-8','完売しました')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
	}
}



#ヨドバシカメラ                                                                                                                                    
sub Yodobashi{
	my $num  = shift;
        my $html = shift;
	my $url  = shift;
	my $iName = shift;
	my $domin = shift;
	my $limit = shift;
	my $store = 'ヨドバシカメラ';
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW encode('utf-8','ヨドバシカメラ')."\n";

        # Name of item                                                                                                 
	$html =~ /data-text="ヨドバシ.com - (.+)通販【全品無料配達】"/;
        my $name = $+;
	print "[NAME]:";
        print encode('utf-8',$name)."\n";

        # Price                                                                                                                                                                  
        $html =~ /id="js_scl_unitPrice">￥(.+)<\/span><span class="taxInfo">/;
        my $price = $+;
	$price = &split_price($price);
	my $RP = &RP($price,0,10);

        print "[PRICE]:";
        print BOLD MAGENTA encode('utf-8','￥');
        print BOLD MAGENTA $price;
        print " including tax\n";
	print "[RealPrice]:";
	print BOLD MAGENTA encode('utf-8','￥');
	print BOLD MAGENTA round($RP)."\n";

        # Inventory
	my $status;                                                                                                                                                              
        $html =~ s/[\s　]+//g;
	print "[STATUS]:";
        if ($html =~ /<spanclass="stockInfo"><spanclass="green">在庫あり/){
		$status =0;
                print  BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);

	}elsif($html =~ /<spanclass="stockInfo"><spanclass="green">在庫残少ご注文はお早めに！/){
		$status =2;
		print BOLD BRIGHT_GREEN encode('utf-8','在庫減少中')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
        }elsif($html =~ /<spanclass="stockInfo"><spanclass="red">お取り寄せ/){
		$status =3;
                print BOLD BRIGHT_GREEN encode('utf-8','お取り寄せ')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
        }elsif($html =~ /<spanid="salesInfoTxt"class="blue">ただいま予約受付中！/){
		$status =1;
                print BOLD BRIGHT_GREEN  encode('utf-8','予約受付中')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
        }elsif($html =~ /<divclass="salesInfo"><p>予定数の販売を終了しました/){
		$status =9;
                print BOLD RED encode('utf-8','完売しました')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);	
	}elsif($html =~ /<divclass="salesInfo"><p>予約受付を終了しました/){
		$status =10;	
		print BOLD RED encode('utf-8','予約受付終了');
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
        }elsif($html =~ /<divclass="salesInfo"><p>販売休止中です/){
		print BOLD RED encode('utf-8','販売休止中')."\n";
		$status =11;
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
	}	
}


# ビックカメラ                                                                                                                                                                  
sub Big_Camera{
	my $num  = shift;
    	my $html = shift;
	my $url = shift;
	my $iName = shift;
	my $domin = shift;
	my $limit = shift;
	my $store = 'ビックカメラ';
	print "[CATEGORY]:";
	print BOLD CYAN "$iName\n";
	print "[STORE]:";
	print BOLD BRIGHT_YELLOW encode('utf-8','ビックカメラ')."\n";

        # Name of item                                                                                   
       $html =~ /data-item-name="(.+)"/;
        my $name = $+;
	print "[NAME]:";
	print encode('utf-8',$name)."\n";

        # Price                                                                                                                                   
        $html =~ /<li>税込：(.+)円/;
        my $price = $+;
	$price = &split_price($price);
	$price = round($price - $price*0.08);
	my $RP = &RP($price,1,5);
	print "[PRICE]:";
	print BOLD MAGENTA encode('utf-8','￥');
	print BOLD MAGENTA $price;
	print " excluding tax\n";
	print "[RealPrice]:";
	print BOLD MAGENTA encode('utf-8','￥');
	print BOLD MAGENTA round($RP)."\n";

        # Inventory
	my $status;                                                                                                               
	$html =~ s/[\s　]+//g;
	print "[STATUS]:";
    	if ($html =~ /<p><spanclass="label_green">在庫あり<\/span><\/p>/){
		$status =0;
		print  BOLD BRIGHT_GREEN encode('utf-8','在庫あり')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);

    	}elsif($html =~ /<p><spanclass="label_orange">お取り寄せ<\/span><\/p>/){
		$status =3;
		print BOLD BRIGHT_GREEN encode('utf-8','お取り寄せ')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
    	}elsif($html =~ /<p><spanclass="label_blue">予約受付中<\/span><\/p>/){
		$status =1;
		print BOLD BRIGHT_GREEN  encode('utf-8','予約受付中')."\n";
		 &save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
    	}elsif($html =~ /<p><spanclass="label_gray">完売しました<\/span><\/p>/){
		$status =9;
		print BOLD RED encode('utf-8','完売しました')."\n";
		&save_file($num,$name,$price,$url,$store,$iName,$domin,$status,$RP,$limit);
	}
}



sub split_price {
	my $price = shift;
	my $real_price;
	if ($price =~ /,/){
		$price =~ s/,//g;
		$real_price = $price;
	}else{
		 $real_price = $price;
	}
	$real_price;
}


sub RP {
	my $price  = shift; # raw price
	my $tax_id = shift; # 0:including tax,   1:excluding tax
	my $point  = shift; # percentage of point
	my $RP;

	if($tax_id == 1){
		$price = $price + $price*0.08;
	}
	if($point > 0){
		$point = $price*($point/100);
	}
	# 実価格 = 税込価格 - ポイント
	$RP = $price - $point;
	$RP;
}





sub save_file {
	my $num   = shift;
	my $name  = shift;
	my $price = shift;
	my $url   = shift;
	my $store = shift;
	my $iName = shift;
	my $domin = shift;
	my $status= shift; # just a number
	my $RP    = shift;
	   $RP    = abs($RP);
	my $limit = shift;
	
	my $saved_count = 1;
	my $saved_count_max;
	my $status_jpn;
	my $NID = 'In STOCK';

	my $min_name;
	my $min_price;
	my $min_url;
	my $min_store;

	# 商品価格を最安値として仮定
	my $min_list_num   = $num;
	my $min_list_price = $price;
	my $min_list_RP    = $RP;
	my $min_list_name  = $name;
	my $min_list_url   = $url;
	my $min_list_store = $store;
	my $min_list_domin = $domin;



	my $max_saved_count = 0;
	my $max_saved_count_price;
	my $max_saved_count_status;

	my $count = 0;
	my $deduction = 0;

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
	# localtime関数からは1900年から数えた年が返却される。
	$year += 1900;
	# 月は0から始まるので、表示するときは1を加える。
	$mon++;
	# year:month:day:hour:minute:second
	my $time = $year.":".$mon.":".$mday.":".$hour.":".$min.":".$sec;
	my $min_list_time = $time;
	open(W, "+< In_stock.csv")||die "can not open 'In_stock':$!\n";
	while(my $line = <W>){ 
		my @rec = split( /,/,  $line, 16);
		my  $num_list            = $rec[0];		
		my  $name_list           = $rec[1];
		my  $price_list          = $rec[2];
		my  $RP_list             = $rec[3];
		my  $min_list_num_list   = $rec[4];
		my  $min_list_price_list = $rec[5];
		my  $min_list_RP_list    = $rec[6];
		my  $url_list            = $rec[7];
		my  $domin_list          = $rec[8];
		my  $store_list          = $rec[9];
		my  $status_list         = $rec[10];
		my  $status_jpn_list     = $rec[11];
		my  $time_list           = $rec[12];
		my  $saved_count_list    = $rec[13];
		my  $limit_list          = $rec[14];
		my  $iName_list          = $rec[15];
		chomp($iName_list);		

		# 在庫中の最安値を求める
		if (($price_list ne 'PRICE')&&($status<=3)&&($price =~ /^\d+$/)){
			# 同じ商品のとき	
			if ($iName eq $iName_list){
				# リストの価格が最安値よりも安いかどうか		
				if($price_list <= $min_list_price){
					# そのリストの価格を最安値に変更
					$min_list_num   = $num_list;
					$min_list_price = $price_list;
					$min_list_RP    = $RP_list;
					$min_list_name  = $name_list;
					$min_list_url   = $url_list;
					$min_list_store = $store_list;
					$min_list_domin = $domin_list;
					$min_list_time  = $time_list;
				}
			}	
		}
		# 在庫がないときはお知らせ＆保存はしない
                if($status >= 8){
                         $count=1;
                 }

		# 在庫リストに保存されているとき
		if($url eq $url_list){
			$saved_count ++;
#			print "[saved_count]:".$saved_count."\n";
#			print "[saved_count_list]:".$saved_count_list."\n";
#			print "[max_saved_count]:".$max_saved_count."\n";
			$count = 1;
			# リストのsave_countが最高値よりも大きいとき
			if($saved_count_list > $max_saved_count){
#				print "AAA\n";
				$max_saved_count        = $saved_count_list;
				$max_saved_count_status = $status_list;
				$max_saved_count_price  = $price_list;
			}
		}
	}
	
	if($saved_count >= 2){
		$deduction = $price - $max_saved_count_price;
		# 在庫情報が以前と変化しているとき
#		print BOLD BRIGHT_YELLOW "status-> $status  max_saved_count_status-> $max_saved_count_status\n";
#		print BOLD BRIGHT_YELLOW "price-> $price   max_saved_count_price-> $max_saved_count_price\n";
		if($status ne $max_saved_count_status){
			$count = 0;
			$NID   = 'STATUS CHANGE';
			# 値下げが生じたとき
		}elsif($deduction < 0){
		#	$count = 0;
		#	$NID   = 'PRICE REDUCTION';
			# さらに下限値を下回ったとき
			if($price <= $limit){
				$count = 0;
				$NID   = 'LOWER THAN LIMIT';
			}
		}
	}		
		
	

	if($status<=3){
		print "[TheLowestPrice]:";
		print BOLD BRIGHT_RED encode('utf-8','￥');
		print BOLD BRIGHT_RED $min_list_price."\n";
	}




	if ($count == 0){
		if($status==0){
			$status_jpn ='在庫あり';
		}elsif($status==1){
			$status_jpn ='予約受付中';
		}elsif($status==2){
			$status_jpn ='在庫減少中';
		}elsif($status==3){
			$status_jpn ='お取り寄せ';
		}		
		&Notify($name,$price,$url,$store,$min_list_price,$min_list_url,$iName,$num,$min_list_domin,$min_list_num,$deduction,$time,$status_jpn,$NID,$limit);
		print W $num.",".encode('utf-8',$name).",".$price.",".round($RP).",".$min_list_num.",".$min_list_price.",".round($min_list_RP).",".$url.",".$domin.",".encode('utf-8',$store).",".$status.",".encode('utf-8',$status_jpn).",".$time.",".$saved_count.",".$limit.",".$iName."\n";
	}else{
		#print "Because the URL already has been saved, there is no notice.\n";
	}
	close(W);
} 
