# fuzzy_match

Find a needle in a haystack based on string similarity (using the Pair Distance algorithm and Levenshtein distance) and regular expressions.

Replaces [`loose_tight_dictionary`](https://github.com/seamusabshere/loose_tight_dictionary) because that was a confusing name.

## Quickstart

    >> require 'fuzzy_match'
    => true 
    >> FuzzyMatch.new(['seamus', 'andy', 'ben']).find('Shamus')
    => "seamus"

## Default matching (string similarity)

If you configure nothing else, string similarity matching is used. That's why we call it fuzzy matching.

The algorithm is [Dice's Coefficient](http://en.wikipedia.org/wiki/Dice's_coefficient) (aka Pair Distance) because it seemed to work better than Jaro Winkler, etc.

## Rules (regular expressions)

You can improve the default matchings with rules, which are generally regular expressions.

    >> require 'fuzzy_match'
    => true 
    >> matcher = FuzzyMatch.new(['Ford F-150', 'Ford F-250', 'GMC 1500', 'GMC 2500'], :blockings => [ /ford/i, /gmc/i ], :normalizers => [ /K(\d500)/i ], :identities => [ /(f)-?(\d\d\d)/i ])
    => #<FuzzyMatch: [...]> 
    >> matcher.find('fordf250')
    => "Ford F-250" 
    >> matcher.find('gmc truck k1500')
    => "GMC 1500" 

### Blockings

Group records together.

Setting a blocking of `/Airbus/` ensures that strings containing "Airbus" will only be scored against to other strings containing "Airbus". A better blocking in this case would probably be `/airbus/i`.

### Normalizers (formerly called tighteners)

Strip strings down to the essentials.

Adding a normalizer like `/(boeing).*(7\d\d)/i` will cause "BOEING COMPANY 747" and "boeing747" to be scored as if they were "BOEING 747" and "boeing 747", respectively. See also "Case sensitivity" below.

### Identities

Prevent impossible matches.

Adding an identity like `/(F)\-?(\d50)/` ensures that "Ford F-150" and "Ford F-250" never match.

### Stop words

Ignore common and/or meaningless words.

Adding a stop word like `THE` ensures that it is not taken into account when comparing "THE CAT", "THE DAT", and "THE CATT"

## Find options

* `read`: how to interpret each record in the 'haystack', either a Proc or a symbol
* `must_match_blocking`: don't return a match unless the needle fits into one of the blockings you specified
* `must_match_at_least_one_word`: don't return a match unless the needle shares at least one word with the match
* `first_blocking_decides`: force records into the first blocking they match, rather than choosing a blocking that will give them a higher score
* `gather_last_result`: enable `last_result`

### `:read`

So, what if your needle is a string like `youruguay` and your haystack is full of `Country` objects like `<Country name:"Uruguay">`?

    >> FuzzyMatch.new(Country.all, :read => :name).find('youruguay')
    => <Country name:"Uruguay">

## Case sensitivity

String similarity is case-insensitive. Everything is downcased before scoring. This is a change from previous versions.

Be careful when trying to use case-sensitivity in your rules; in general, things are downcased before comparing.

## Dice's coefficient edge case

In edge cases where Dice's finds that two strings are equally similar to a third string, then Levenshtein distance is used. For example, pair distance considers "RATZ" and "CATZ" to be equally similar to "RITZ" so we invoke Levenshtein.

    >> require 'amatch'
    => true 
    >> 'RITZ'.pair_distance_similar 'RATZ'
    => 0.3333333333333333 
    >> 'RITZ'.pair_distance_similar 'CATZ'  # <-- pair distance can't tell the difference, so we fall back to levenshtein...
    => 0.3333333333333333 
    >> 'RITZ'.levenshtein_similar 'RATZ'
    => 0.75 
    >> 'RITZ'.levenshtein_similar 'CATZ'    # <-- which properly shows that RATZ should win
    => 0.5 

## Production use

Over 2 years in [Brighter Planet's environmental impact API](http://impact.brighterplanet.com) and [reference data service](http://data.brighterplanet.com).

We often combine `fuzzy_match` with [`remote_table`](https://github.com/seamusabshere/remote_table) and [`errata`](https://github.com/seamusabshere/errata):

- download table with `remote_table`
- correct serious or repeated errors with `errata`
- `fuzzy_match` the rest

## Glossary

The admittedly imperfect metaphor is "look for a needle in a haystack"

* needle: the search term
* haystack: the records you are searching (<b>your result will be an object from here</b>)

## Credits (and how to make things faster)

If you add the [`amatch`](http://flori.github.com/amatch/) gem to your Gemfile, it will use that, which is much faster (but [segfaults have been seen in the wild](https://github.com/flori/amatch/issues/3)). Thanks [Flori](https://github.com/flori)!

Otherwise, pure ruby versions of the string similarity algorithms derived from the [answer to a StackOverflow question](http://stackoverflow.com/questions/653157/a-better-similarity-ranking-algorithm-for-variable-length-strings) and [the text gem](https://github.com/threedaymonk/text/blob/master/lib/text/levenshtein.rb) are used. Thanks [marzagao](http://stackoverflow.com/users/10997/marzagao) and [threedaymonk](https://github.com/threedaymonk)!

## Authors

* Seamus Abshere <seamus@abshere.net>
* Ian Hough <ijhough@gmail.com>
* Andy Rossmeissl <andy@rossmeissl.net>

## Copyright

Copyright 2012 Brighter Planet, Inc.
