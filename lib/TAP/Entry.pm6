package TAP {
	role Entry {
		has Str $.raw;
		method to_string { ... }
		method Str {
			return $.raw // $.to_string;
		}
	}
	class Version does Entry {
		has Int:D $.version;
		method to_string() {
			return "TAP Version $!version";
		}
	}
	class Plan does Entry {
		has Int:D $.tests = !!! 'tests is required';
		has Bool $.skip-all;
		has Str $.explanation;
		method to_string() {
			return ('1..' ~ $!tests ~ ($!skip-all ?? ('#SKIP', $!explanation).grep(*.defined) !! () )).join(' ');
		}
	}

	enum Directive <No-Directive Skip Todo>;

	class Test does Entry {
		has Bool:D $.ok;
		has Int $.number;
		has Str $.description;
		has Directive:D $.directive = No-Directive;
		has Str $.explanation;

		method is-ok() {
			return $!ok || $!directive ~~ Todo;
		}
		method to_string() {
			my @ret = ($!ok ?? 'ok' !! 'not ok'), $!number, '-', $!description;
			@ret.push('#'~$!directive.uc, $!explanation) if $!directive;
			return @ret.grep(*.defined).join(' ');
		}
	}
	class Bailout does Entry {
		has Str $.explanation;
		method to_string {
			return ('Bail out!', $.explanation).grep(*.defined).join(' ');
		}
	}
	class Comment does Entry {
		has Str $.comment = !!! 'comment is required';
		method to_string {
			return "# $!comment";
		}
	}
	class YAML does Entry {
		has Str:D $.content;
		method to_string {
			return "  ---\n" ~ $!content.subst(/^^/, '  ', :g) ~~ '  ...'
		}
	}
	class Unknown does Entry {
		method to_string {
			$!raw // fail 'Can\'t stringify empty Unknown';
		}
	}

	role Entry::Handler {
		method handle-entry(Entry) { ... }
		method end-entries() { }
	}

	role Session does Entry::Handler {
		has Str $.name;
		method close-test() { ... }
	}

	class Output does Entry::Handler {
		has IO::Handle $.handle = $*OUT;
		method handle-entry(Entry $entry) {
			$!handle.say($entry.Str);
		}
		method end-entries() {
			$!handle.flush;
		}
		method open(Str $filename) {
			my $handle = open $filename, :w;
			$handle.autoflush(True);
			return Output.new(:$handle);
		}
	}
}
