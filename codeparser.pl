#! /usr/bin/perl

use Thread;
use warnings;
use strict;

my $argc=scalar(@ARGV);
our $path;
our $log_prefix;
if($argc eq 1){
	($path) = @ARGV;
	$log_prefix="";
}elsif($argc eq 2){
    ($path,$log_prefix)  = @ARGV ;
}else{
	die "wrong argument";
}
our $type="_WARNING|_FATAL|log.warning|LOG.warning|LOG.fatal|log.fatal|log.error|log.critical|CRITICAL|LOG.warn|WARNING_LOG|FATAL_LOG|logger.warn|log.warn";
our $file_type=".*\\.\\(c\\|h\\|pl\\|cpp\\|php\\|py\\|java\\|cc\\)";
my @fileList = `find $path -regex "$file_type" | xargs egrep -H "${log_prefix}($type)" | awk -F':' '{print \$1}' | sort |uniq`;

#our $type="WARNING";
&main(@fileList);

sub parse_file()
{
    my ($single_file)=@_;

    #���py�Ļ�����;��β�������Ҫ������
    my $tail;
    if($single_file =~ /.*\.py/){
    	$tail="";
    }else{
    	$tail=";";
    }

    my $openrs = open INPUT,"<",$single_file;
    if (! $openrs)
    {
        print "err open file $single_file \n";
    }
    my $lineNo = 0;
    my $log_buf;
    my $log_type;
    my $log_count=0;#log count in many line
        while(<INPUT>)
        {
            chomp;
            $lineNo++;
            my $baseName = `basename $single_file`;
            chomp $baseName;

            if($log_count eq 0 && $_ !~ /${log_prefix}($type)/){
            	next;
            }

            #�ⲿ��ƥ����""��Ϊ��־�ĸ�ʽ
            #ƥ�����У���);��β
            if (/${log_prefix}($type)\s*(,\s*|\().*\s*"(.*)".*\)$tail\s*(\s*|\\\s*)$/)#log_prefix log_type space(, or ()space"chars"chars);spaces$
            {
                print $baseName,"%%",$lineNo,"%%",$1,"%%",$3,"\n";
                next;
            }elsif(/${log_prefix}($type)\s*(,\s*|\()(\s*|.*)\s*"(.*?)(".*|"\s*,.*|"\),.*|"\s*,\s*\\|\\)\s*$/){
            #ƥ�䲿���У����log_count���ռ���־
                $log_buf=$4;
                $log_count=1;
                $log_type=$1;
                next;
            }elsif(/${log_prefix}($type)\s*(,\s*|\()(\s*|\s*\\)\s*$/){
            	#��һ��ƥ�䵽����ʼ��������������һ��ƴ����־
                $log_buf="";
                $log_count=1;
                $log_type=$1;
                next;
            }elsif($log_count gt 0){
            	#ƴ����־
                if(/("|\\)(.*)"/){
                    $log_buf = "$log_buf"."$2";
                    $log_count+=1;
                }else{
                    $log_count+=1;
                }
                #�ҵ���־��β����ӡ������־��Ϣ
                if(/\)\s*$tail\s*(\\\s*|\s*)$/){
#print "can print now $lineNo\n";
                    print $baseName,"%%",$lineNo,"%%",$log_type,"%%",$log_buf,"\n";
                    $log_count=0;
                    $log_type="";
                    $log_buf="";
                }
                next;
            }

            #�ⲿ��ƥ����''��Ϊ��־�ĸ�ʽ������������
            if (/${log_prefix}($type)\s*(,\s*|\().*\s*'(.*)'.*\)$tail\s*(\s*|\\\s*)$/)#log_prefix log_type space(, or ()space"chars"chars);spaces$
            {
                print $baseName,"%%",$lineNo,"%%",$1,"%%",$3,"\n";
            }elsif(/${log_prefix}($type)\s*(,\s*|\()(\s*|.*)\s*'(.*?)('.*|'\s*,.*|'\),.*|'\s*,\s*\\|\\)\s*$/){
            #ƥ�䲿���У����log_count���ռ���־
                $log_buf=$4;
                $log_count=1;
                $log_type=$1;
            }elsif(/${log_prefix}($type)\s*(,\s*|\()(\s*|\s*\\)\s*$/){
                $log_buf="";
                $log_count=1;
                $log_type=$1;
            }elsif($log_count gt 0){
                if(/('|\\)(.*)'/){
                    $log_buf = "$log_buf"."$2";
                    $log_count+=1;
                }else{
                    $log_count+=1;
                }
                if(/\)\s*$tail(\\\s*|\s*)$/){
#print "can print now $lineNo\n";
                    print $baseName,"%%",$lineNo,"%%",$log_type,"%%",$log_buf,"\n";
                    $log_count=0;
                    $log_type="";
                    $log_buf="";
                }
            }
        }
    close INPUT;
}

sub main()
{
    my @files = @_;
    my $file_num=scalar(@files);
    my @threads;
    my $thread_id=0;

    foreach my $single_file (@files)
    {
      chomp $single_file;
      $threads[$thread_id]=Thread->new(\&parse_file,$single_file);
      $thread_id++;
    }
    foreach my $thread (@threads) {
    	$thread->join();
    }
}

