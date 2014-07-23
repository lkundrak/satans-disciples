use strict;
use warnings;

use Database::DumpTruck;
use HTML::TreeBuilder 4;
use LWP::Simple;

my $dt = new Database::DumpTruck ({ dbname => 'data.sqlite', table => 'swdata' });

sub do_page
{
	my $id = shift;

	my $tree = new_from_content HTML::TreeBuilder (get ("http://www.peticie.com/signatures/gothoom_2014_otvoreny_list_ministrovi_kultury_prezidentovi_pz/start/$id"));
	my $table = $tree->look_down (_tag => 'table', id => 'signatures');

	my $last_id;
	foreach my $row ($table->look_down (_tag => 'tr')) {
		my @line = map { $_->as_text } $row->look_down (_tag => 'td');
		s/^\s*// foreach @line;

		# Skip header
		next unless @line;

		$last_id = $line[0];

		# Bogus entry
		next unless @line > 2;

		$dt->insert ({
			Id	=> $line[0],
			Name	=> $line[1],
			Location => $line[2],
			Date	=> $line[3],
		});
	}

	$tree->delete;
	return $last_id;
}

my $id = eval { $dt->get_var ('last_id') } || 0;
do {
	$id = do_page ($id);
	$dt->save_var ('last_id', $id) if defined $id;
} while (defined $id);
