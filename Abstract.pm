# This module is for saving development time and 
# programming space with the Perl DBI.

package Relations::Abstract;
require Exporter;
require DBI;
require 5.004;

use Relations;
use Relations::Query;

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).

# Copyright 2001 GAF-3 Industries, Inc. All rights reserved.
# Written by George A. Fitch III (aka Gaffer), gaf3@gaf3.com

# This program is free software, you can redistribute it and/or modify it under
# the same terms as Perl itself

$Relations::Abstract::VERSION='0.93';

@ISA = qw(Exporter);

@EXPORT = qw(
              new
            );		

@EXPORT_OK = qw(
                new
                delete_rows
                insert_id
                insert_row
                run_query 
                select_column 
                select_field 
                select_insert_id
                select_matrix
                select_row 
                update_rows
               );

%EXPORT_TAGS = ();

# From here on out, be strict and clean.

use strict;



# Create a Relations::Abstract object.

sub new {

  my ($type) = shift;

  # Get all the arguments passed

  my ($dbh) = rearrange(['DBH'],@_);

  # Create the hash to hold all the vars
  # for this object.

  my $self = {};

  # Bless it with the type sent (I think this
  # makes it a full fledged object)

  bless $self, $type;

  # Add the info into the hash only if it was sent

  $self->{dbh} = $dbh if $dbh;

  # Return thyself

  return $self;

}


# This routine just sets the default database handle to use.

sub set_dbh {

  # Know thyself

  my $self = shift;

  # Get the DBH sent

  my ($dbh) = rearrange(['DBH'],@_);

  # Set the database handle.

  $self->{dbh} = $dbh;

}



# This routine runs a query and reports if there's an error.

sub run_query {

  ### What we're doing here is sending the query string to the dbh, and
  ### reporting an error if the execute failed.

  # Know thyself

  my $self = shift;

  # Get the query sent

  my ($query) = rearrange(['QUERY'],@_);

  # If we were sent a query object, get the query 
  # string from it. 

  $query = $query->get() if ref $query;

  # Declare a statement handle and prepare the query.

  my ($sth) = $self->{dbh}->prepare($query);

  # Execute it.

  $sth->execute() or $self->report_error('run_query',$query);

  # Finish it off.

  $sth->finish();

}



# This routine runs a query using a where clause, returns the requested 
# items value and reports if there's an error.

sub select_field {

  ### What we're doing here is creating and sending the query string to the
  ### dbh, retreiving the requested item and reporting an error if the execute failed.

  # Know thyself

  my $self = shift;

  # Get the field, table, where clause and dbh sent

  my ($field,$table,$where,$query) = rearrange(['FIELD','TABLE','WHERE','QUERY'],@_);

  # Unless we were sent query info

  unless ($query) {

    # Get the info for the where clause;

    $where = equals_clause($where);

    # Declare a statement handle and prepare the query.

    $query = "select $field from $table where $where";

  } else {

    # If we were sent a query object, get the query 
    # string from it. 

    $query = $query->get() if ref $query;

  }

  # Declare a statement handle and prepare the query.

  my ($sth) = $self->{dbh}->prepare($query);

  # Execute it.

  $sth->execute() or $self->report_error('select_field',$query) and return '';

  # Declare hash for retrieving value, and variable to hold value.

  my ($hash_ref,$value);

  # If we got something returned

  if ($hash_ref = $sth->fetchrow_hashref()) {

    # Get the value returned.

    $value = $hash_ref->{$field};

  }

  # Finish it off.

  $sth->finish();

  # Return the value.

  return $value;

}



# This routine select a row of data given a table and a where clause, 
# returns the hash reference, and reports if there's an error.

sub select_row {

  ### What we're doing here is creating the query string and sending it to 
  ### the dbh, retreiving the frist row's hash, returning it unless there's 
  ### an error. If so we'll report the error.

  # Know thyself

  my $self = shift;

  # Get the table and where clause sent

  my ($table,$where,$query) = rearrange(['TABLE','WHERE','QUERY'],@_);

  # Unless we were sent query info

  unless ($query) {

    # Get the info for the where clause;

    $where = equals_clause($where);

    # Form query

    $query = "select * from $table where $where"; 

  } else {

    # If we were sent a query object, get the query 
    # string from it. 

    $query = $query->get() if ref $query;

  }

  # Declare a statement handle and prepare the query.

  my ($sth) = $self->{dbh}->prepare($query);

  # Execute it.

  $sth->execute() or $self->report_error('select_row',$query) and return '';

  # Get the value returned.

  my ($hash_ref) = $sth->fetchrow_hashref();

  # Finish it off.

  $sth->finish();

  # Return the value.

  return $hash_ref;

}



# This routine select a column of data given a field, table and a where
# clause, returns the array reference, and reports if there's an error.

sub select_column {

  ### What we're doing here is creating the query string and sending it to 
  ### the dbh, retreiving the requested column's values, returning it unless 
  ### there's an error. If so we'll report the error.

  # Know thyself

  my $self = shift;

  # Get the table and where clause sent

  my ($field,$table,$where,$query) = rearrange(['FIELD','TABLE','WHERE','QUERY'],@_);

  # Unless we were sent query info

  unless ($query) {

    # Get the info for the where clause;

    $where = equals_clause($where);

    # Declare a statement handle and prepare the query.

    $query = "select $field from $table where $where";

  } else {

    # If we were sent a query object, get the query 
    # string from it. 

    $query = $query->get() if ref $query;

  }

  # Declare a statement handle and prepare the query.

  my ($sth) = $self->{dbh}->prepare($query);

  # Execute it.

  $sth->execute() or $self->report_error('select_colum',$query) and return '';

  # Create an array to hold the data

  my (@column) = ();

  # Get the values returned.

  my ($hash_ref);
    
  while ($hash_ref = $sth->fetchrow_hashref()) {

    # Add them to the column array.

    push @column,$hash_ref->{$field};

  }

  # Finish it off.

  $sth->finish();

  # Return the value.

  return \@column;

}



# This routine select a column of data given a field, table and  a where
# clause, returns the array reference, and reports if there's an error.

sub select_matrix {

  ### What we're doing here is creating the query string and sending it to 
  ### the dbh, retreiving the rows of hashes, returning it unless there's 
  ### an error. If so we'll report the error.

  # Know thyself

  my $self = shift;

  # Get the table and where clause sent

  my ($table,$where,$query) = rearrange(['TABLE','WHERE','QUERY'],@_);

  # Unless we were sent query info

  unless ($query) {

    # Get the info for the where clause;

    $where = equals_clause($where);

    # Declare a statement handle and prepare the query.

    $query = "select * from $table where $where";

  } else {

    # If we were sent a query object, get the query 
    # string from it. 

    $query = $query->get() if ref $query;

  }

  # Declare a statement handle and prepare the query.

  my ($sth) = $self->{dbh}->prepare($query);

  # Execute it.

  $sth->execute() or $self->report_error('select_matrix',$query) and return '';

  # Create an array to hold the data

  my (@matrix) = ();

  # Get the values returned.

  my ($hash_ref);
    
  while ($hash_ref = $sth->fetchrow_hashref()) {

    # Create a hash to hold the data

    my (%matrix) = %$hash_ref;

    # Add them to the column array.

    push @matrix,\%matrix;

  }

  # Finish it off.

  $sth->finish();

  # Return the value.

  return \@matrix;

}



# This routine inserts a row of data into a table and returns the number 
# of affected rows. If there's an error it returns 0.

sub insert_row {

  ### What we're doing here is sending the query string to the dbh, and 
  ### returning the number of rows affected, unless there's an error. If
  ### there's an error, we'll send back a 0.

  # Know thyself

  my $self = shift;

  # Get the table and set clause sent

  my ($table,$set) = rearrange(['TABLE','SET'],@_);

  # Get the info for the where clause;

  $set = assign_clause($set);

  # Form query

  my ($query) = "insert into $table set $set"; 

  # Declare a statement handle and prepare the query.

  my ($sth) = $self->{dbh}->prepare($query);

  # Execute it.

  $sth->execute() or $self->report_error('insert_id',$query) and return 0;

  # Finish it off.

  $sth->finish();

  # Return the number of rows affected

  return $sth->rows();

}



# This routine inserts a row data into a table with an autoincrementing 
# primary key and returns the new id. If there's an error it returns a
# zero.

sub insert_id {

  ### What we're doing here is sending the query string to the dbh, retreiving 
  ### the new id, and sending it back, unless there's an error. If there's an 
  ### error, we'll send backa zero.

  # Know thyself

  my $self = shift;

  # Get the table and set clause sent

  my ($table,$set) = rearrange(['TABLE','SET'],@_);

  # Get the info for the where clause;

  $set = assign_clause($set);

  # Form query

  my ($query) = "insert into $table set $set"; 

  # Declare a statement handle and prepare the query.

  my ($sth) = $self->{dbh}->prepare($query);

  # Execute it.

  $sth->execute() or $self->report_error('insert_id',$query) and return 0;

  # Finish it off.

  $sth->finish();

  # Return the new id using and old friend of ours.

  return $self->select_field(-field => 'id', -query => 'select last_insert_id() as id');

}



# This routine is a combo of select_item and insert_id. It first tries to 
# lookup a record's id using id, table, and a where clause. If the lookup 
# is unsuccessful, it'll try to add the record to the table and then return 
# the new id.

sub select_insert_id {

  ### What we're doing here trying select_item and returning the id if 
  ### succesful. Else, trying insert_id, returning the new if successful.
  ### Else, returning zero.

  # Know thyself

  my $self = shift;

  # Get the table, where clause, and set clause sent

  my ($id,$table,$where,$set) = rearrange(['ID','TABLE','WHERE','SET'],@_);

  # Declare the id variables

  my ($old_id,$new_id);
  
  # If the data's already there.

  if ($old_id = $self->select_field($id,$table,$where)) {

    # Return the old id

    return $old_id;

  }

  # If we could add the data

  if ($new_id = $self->insert_id($table,$set)) {

    # Return the new id.

    return $new_id;

  }

  # If we've come this far, then neither was successful. Indicate this.

  return 0;

}



# This routine updates rows data in a table and returns the number of 
# updated rows. If there's an error it returns 0.

sub update_rows {

  ### What we're doing here is sending the query string to the dbh, and 
  ### returning the number of rows affected, unless there's an error. If
  ### there's an error, we'll send back a 0.

  # Know thyself

  my $self = shift;

  # Get the table where clause, and set clause sent

  my ($table,$where,$set) = rearrange(['TABLE','WHERE','SET'],@_);

  # Get the info for the set and where clause;

  $set = assign_clause($set);
  $where = equals_clause($where);

  # Form query

  my ($query) = "update $table set $set where $where"; 

  # Declare a statement handle and prepare the query.

  my ($sth) = $self->{dbh}->prepare($query);

  # Execute it.

  $sth->execute() or $self->report_error('update_rows',$query) and return 0;

  # Finish it off.

  $sth->finish();

  # Return the number of rows affected

  return $sth->rows();

}



# This routine update a row data into a table and returns the number of 
# delete rows. If there's an error it returns 0.

sub delete_rows {

  ### What we're doing here is sending the query string to the dbh, and 
  ### returning the number of rows affected, unless there's an error. If
  ### there's an error, we'll send back a 0.

  # Know thyself

  my $self = shift;

  # Get the table and where clause criteria sent

  my ($table,$where) = rearrange(['TABLE','WHERE'],@_);

  # Get the info where clause;

  $where = equals_clause($where);

  # Form query

  my ($query) = "delete from $table where $where"; 

  # Declare a statement handle and prepare the query.

  my ($sth) = $self->{dbh}->prepare($query);

  # Execute it.

  $sth->execute() or $self->report_error('delete_rows',$query) and return 0;

  # Finish it off.

  $sth->finish();

  # Return the number of rows affected

  return $sth->rows();

}



# This routine reports a failed query if PrintError is enabled in the dbh.

sub report_error {

  # Know thyself

  my $self = shift;

  # If DBI isn't printing errors neither are we.

  return 1 unless $self->{dbh}->{PrintError};

  # Get the location of the failure and and that query that caused the 
  # failure.

  my $location = shift;
  my $query = shift;

  # Tell the user what's up.

  print "$location failed:\n$query\n"; 

}



$Relations::Abstract::VERSION;

__END__

=head1 NAME

Relations::Abstract - DBI/DBD::mysql Functions to Save Development Time and Code Space

=head1 SYNOPSIS

  # DBI/Relations Script that creates a couple tables and adds to them.

  use DBI;
  use Relations::Abstract;

  $dsn = "DBI:mysql:mysql";

  $dbh = DBI->connect($dsn,$username,$password,{PrintError => 1, RaiseError => 0});

  # Create a Relations::Abstract object using the database handle

  $abs = new Relations::Abstract($dbh);

  # Drop, create and use a database

  $abs->run_query("drop database if exists abs_test");
  $abs->run_query("create database abs_test");
  $abs->run_query("use abs_test");

  # Create a table

  $abs->run_query("
    create table sizes
      (
        size_id int unsigned auto_increment,
        num int unsigned,
        descr varchar(16),
        primary key (size_id),
        unique descr (descr),
        unique num (num),
        index (size_id)
      )
  ");

  # Retreive size 12 if already within the database, else add
  # size 12 information into the database and get its size_id.

  $size_id = select_insert_id(-dbh   => $dbh,
                              -id    => 'size_id',
                              -table => "sizes",
                              -where => {num          => 12},
                              -set   => {num          => 12,
                                         description  => $dbh->quote('Bigfoot')});

=head1 ABSTRACT

This perl library uses perl5 objects to simplify using the DBI 
DBD::mysql modules. It takes the most common (in my experience) 
collection of DBI calls to a MySQL databate, and changes them 
to one liners. It utilizes a object-oriented programming style.

The current version of Relations is available at

  http://www.gaf3.com

=head1 DESCRIPTION

=head2 WHAT IT DOES

All Abstract does is take information about what you want to do
to a database and does it by creating and executing SQL statements via
DBI. That's it. It's there just to simplify the amount of code one has
to write and maintain with respect long and complex database tasks.

The simplest example is the run_query function. It takes a SQL string 
(and an optional dbh) and prepares, executes, and finishes that SQL
string via DBI.

  $abs->run_query("drop database if exists abs_test");

This puts "drop database if exists abs_test" through the
prepare, execute, and finish functions of DBI.

The most complex example is the select_insert_id function. Its used
for either looking up a certain record's primary id value if it already
exists in the table, or adding that record and retreiving its new primary 
id value if it does not already exist in the table.  

  $size_id = $abs->select_insert_id(-dbh   => $dbh,
                                    -id    => 'size_id',
                                    -table => "sizes",
                                    -where => {num          => 12},
                                    -set   => {num          => 12,
                                               description  => $dbh->quote('Bigfoot')});

This puts several SQL string through the prepare, execute, and finish 
functions of DBI. 

First using the primary id name, the table name, and the where clause, 
select_insert_id creates the SQL statement, "select size_id from sizes 
where num=12", and prepares, executes, and finishes it. If a row is 
returned, select_insert_id returns the looked up value of size_id.

If a row is not returned, select_insert_id then creates a another SQL 
statement, "insert into sizes set num=12,description='Bigfoot' " using 
the table name, and set clause, and puts it through DBI. After that,
it runs another SQL statement "select last_insert_id() as id" to 
retrieve the new primary id value for the new record. Though the function
is long, it is certainly shorter than 9 calls to DBI functions, and a few
if-else's.

=head2 CALLING RELATIONS::ABSTRACT ROUTINES

All standard Abstract routines use both an ordered and named 
argument calling style. This is because some routines have as many as 
five arguments, and the code is easier to understand given a named 
argument style, but since some people, however, prefer the ordered argument 
style because its smaller, I'm glad to do that too.

If you use the ordered argument calling style, such as

  $hash_ref =  $abs->select_row('sizes',{num => 10});

the order matters, and you should consult the function defintions 
later in this document to determine the order to use.

If you use the named argument calling style, such as

  $hash_ref =  $abs->select_row(-table => 'sizes',
                                -where => {num => 10});

the order does not matter, but the names, and minus signs preceeding them, do.
You should consult the function defintions later in this document to determine 
the names to use.

In the named arugment style, each argument name is preceded by a dash.  
Neither case nor order matters in the argument list.  -table, -Table, and 
-TABLE are all acceptable.  In fact, only the first argument needs to begin with 
a dash.  If a dash is present in the first argument, Relations.pm assumes
dashes for the subsequent ones.

=head2 WHERE AND SET CLAUSES

Many of the Relations functions require arguments named where and set.
These arugments are used to populate (respectively) the 'where' and 'set'
areas of SQL statements. Since both these areas can require a varying number
of entries, each can be sent as a hash, array, or string.

WHERE FUNCTIONALITY

If sent as a hash, a where argument would become a string of $key=$value 
pairs, concatented with an ' and ' and placed right after the where keyword. 

For example,

  $hash_ref =  $abs->select_row(-table => 'sizes',
                                -where => {num         => 10,
                                           description => $dbh->quote('Momma Bear')});

creates and executes the SQL statment "select * from sizes where num=10 and 
description='Momma Bear'".

If sent as an array, a where argument would become a string of array members,
concatented with an ' and '.  and placed right after the 'where' keyword. 

For example,

  $hash_ref =  $abs->select_row(-table => 'sizes',
                                -where => ["num < 8",
                                           "description not in ('Momma Bear','Papa Bear')"]);

creates and executes the SQL statment "select * from sizes where num < 8 and 
description not in ('Momma Bear','Papa Bear')".

If sent as a string, a where is placed as is right after the 'where' keyword.

For example,

  $hash_ref =  $abs->select_row(-table => 'sizes',
                                -where => "num > 10 or (num < 5 and num > 0)");

creates and executes the SQL statment "select * from sizes where num < 8 or 
(num < 5 and num > 0)".

SET FUNCTIONALITY

If sent as a hash, a set argument would become a string of $key=$value 
pairs, concatented with an ',' and placed right after the 'set' keyword. 

For example,

  $abs->insert_row(-table => 'sizes',
                   -set   => {num         => 7,
                              description => $dbh->quote('Goldilocks')});

creates and executes the SQL statment "insert into sizes set num=7, 
description='Goldilocks'".

If sent as an array, a set argument would become a string of array members,
concatented with an ','.  and placed right after the 'set' keyword. 

For example,

  $abs->insert_row(-table => 'sizes',
                   -set   => ["num=7",
                              "description='Goldilocks'"]);

creates and executes the SQL statment "insert into sizes set num=7, 
description='Goldilocks'".

If sent as a string, a set argument is placed as is right after the 
'set' keyword.

For example,

  $abs->insert_row(-table => 'sizes',
                   -set   => "num=7,description='Goldilocks'");

creates and executes the SQL statment "insert into sizes set num=7, 
description='Goldilocks'".

I'm not sure if the set argument needs to be so flexible, but I thought I'd 
make it that way, just in case.

=head1 LIST OF RELATIONS::ABSTRACT FUNCTIONS

An example of each function is provided in 'test.pl'.

=head2 new

  $abs = Relations::Abstract->new($dbh);

  $abs = new Relations::Abstract(-dbh => $dbh);

=head2 delete_rows

  $abs->delete_rows($table,$where,$set);

  $abs->delete_rows(-table => $table,
                    -where => $where,
                    -set   => $set);

Deletes all records from $table that satisfy the $where clause. Uses an 
SQL statement in the form:

  delete from $table where $where;

=head2 insert_id

  $abs->insert_id($table,$set);

  $abs->insert_id(-table => $table,
                  -set   => $set);

For tables with auto incrementing primary keys. Inserts $set into $table
and returns the new primary key value. Uses SQL statements in the form:

  insert into $table set $set;

  select last_insert_id() as id;

=head2 insert_row

  $abs->insert_row($table,$set);

  $abs->insert_row(-table => $table,
                   -set   => $set);

Inserts a row of set into a table. Uses SQL statements in the form:

  insert into $table set $set;

=head2 run_query

  $abs->run_query($query);

  $abs->run_query(-query => $query);

Runs the given query, $query.

=head2 select_column

  $array_ref = $abs->select_column($field,$table,$where);

  $array_ref = $abs->select_column(-field => $field,
                                   -table => $table,
                                   -where => $where);

  $array_ref = $abs->select_column(-field => $field,
                                   -query => $query);

Returns an array reference of all $field values from $table that 
satisfy the $where clause. It can also grab all $field's values from 
the query specified by $query, which can be a string or a 
Relations::Query object. Uses SQL statements in the form:

  select $field from $table where $where; or 
  $query;  

=head2 select_field

  $value = select_field($field,$table,$where);

  $value = select_field(-field => $field,
                        -table => $table,
                        -where => $where);

  $value = select_field(-field => $field,
                        -query => $query);

Returns the first $field value from $table that satisfies the 
$where clause.  It can also grab $field's value from the query 
specified by $query, which can be a string or a Relations::Query 
object. Uses SQL statements in the form: Uses SQL statements in 
the form:

  select $field from $table where $where; or
  $query;  

=head2 select_insert_id

  select_insert_id($id,$table,$where,$set);

  select_insert_id(-id    => $id,
                   -table => $table,
                   -where => $where,
                   -set   => $set);

For tables with auto incrementing primary keys. It first tries to 
return the first $id values from $table that satisfies the criteria
defined by $where. If that doesn't work, it then inserts $set into
$table, and returns the newly generated primary id. It does not use
$id to lookup the primary id value. It uses SQL statements in the 
form:

  select $id from $table where $where;

  insert into $table set $set;

  select last_insert_id() as id;

=head2 select_matrix

  $array_ref = select_matrix($table,$where);

  $array_ref = select_matrix(-table => $table,
                             -where => $where);

Returns an array reference of hash references of all rows $table that 
satisfy the $where clause. It can also grab all values from the query 
specified by $query, which can be a string or a Relations::Query 
object. Uses SQL statements in the form:

  select * from $table where $where; or
  $query;  

=head2 select_row

  $hash_ref = select_row($table,$where);

  $hash_ref = select_row(-table => $table,
                         -where => $where);

Returns a hash reference for the first row in $table that satisfies 
the criteria set by $where. It can also grab the first row from the 
query  specified by $query, which can be a string or a Relations::Query 
object. Uses SQL statements in the form:

  select * from $table where $where; or
  $query;  

=head2 set_dbh

  set_dbh($dbh);

  set_dbh(-dbh => $dbh);

Sets the default database handle to use for all DBI calls. This $dbh can 
be overridden in any of the other functions by sending another $dbh as the
last ordered argument, or as the -dbh named argument.

=head2 update_rows

  update_rows($table,$where,$set);

  update_rows(-table => $table,
              -where => $where,
              -set   => $set);

Updates all rows in $table that satisfy the $where clause with $set. Uses
SQL statements in the form:

  update $table set $set where $where;

=head1 TODO LIST

=head2 Object Oriented interface

=head2 Add select_row_array, select_row_arrayref, and select_row_hashref. 

=head1 OTHER RELATED WORK

=head2 Relations

This perl library contains functions for dealing with databases.
It's mainly used as the the foundation for all the other 
Relations modules. It may be useful for people that deal with
databases in Perl as well.

=head2 Relations::Abstract

A DBI/DBD::mysql Perl module. Meant to save development time and code 
space. It takes the most common (in my experience) collection of DBI 
calls to a MySQL databate, and changes them to one liner calls to an
object.

=head2 Relations::Query

An Perl object oriented form of a SQL select query. Takes hash refs,
array refs, or strings for different clauses (select,where,limit)
and creates a string for each clause. Also allows users to add to
existing clauses. Returns a string which can then be sent to a 
MySQL DBI handle. 

=head2 Relations.Admin.inc.php

Some generalized PHP classes for creating Web interfaces to relational 
databases. Allows users to add, view, update, and delete records from 
different tables. It has functionality to use tables as lookup values 
for records in other tables.

=head2 Relations::Family

A Perl query engine for relational databases.  It queries members from 
any table in a relational database using members selected from any 
other tables in the relational database. This is especially useful with 
complex databases; databases with many tables and many connections 
between tables.

=head2 Relations::Display

An Perl module creating GD::Graph objects from database queries. It 
takes in a query through a Relations::Query object, along with 
information pertaining to which field values from the query results are 
to be used in creating the graph title, x axis label and titles, legend 
label (not used on the graph) and titles, and y axis data. Returns a 
GD::Graph object built from from the query.

=head2 Relations::Choice

An Perl CGI interface for Relations::Family, Reations::Query, and 
Relations::Display. It creates complex (too complex?) web pages for 
selecting from the different tables in a Relations::Family object. 
It also has controls for specifying the grouping and ordering of data
with a Relations::Query object, which is also based on selections in 
the Relations::Family object. That Relations::Query can then be passed
to a Relations::Display object, and a graph or table will be displayed.
A working model already exists in a production enviroment. I'd like to 
streamline it, and add some more functionality before releasing it to 
the world. Shooting for early mid Summer 2001.

=cut