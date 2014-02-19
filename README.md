# Railsprof

Rails CLI utility for profiling via rblineprof with good HTML output.

![image](https://f.cloud.github.com/assets/14217/2202180/a8cd5ab4-98fc-11e3-8c1a-3ca127f26ae2.png)

```
$ be railsprof -n5 -g hasherdashery -q key=REDACTED /api/v3/communities/123/portals
info   App loading...
info   App loaded in 12.02 secs
info   Warmup #1 completed in 1133.25ms
info   Profiling....
info   Profile #1 completed in 467.55ms
info   Profile #2 completed in 463.84ms
info   Profile #3 completed in 447.02ms
info   Profile #4 completed in 458.12ms
info   Profile #5 completed in 448.42ms
info   All profiles completed in 2287.82ms

-- Top files by execution time (total / child / excl / filename) --
  2230.80ms   2229.39ms      1.39ms  app/controllers/api/v3/base_controller.rb
  2163.61ms   4285.14ms      0.59ms  app/controllers/api/v3/communities_controller.rb
  2162.76ms   4174.57ms    110.10ms  lib/api/interaction_responder.rb
  1988.38ms   1986.27ms      2.11ms  lib/api/utilities.rb
  1986.27ms   3698.37ms    920.62ms  hasherdashery-200a6c732704/lib/hasherdashery.rb
  1917.27ms   3330.16ms    545.64ms  hasherdashery-200a6c732704/lib/hasherdashery/tailor.rb
  1668.67ms   2632.86ms    888.21ms  hasherdashery-200a6c732704/lib/hasherdashery/property.rb
  1629.22ms   2307.68ms   1155.85ms  hasherdashery-200a6c732704/lib/hasherdashery/value.rb
  1461.89ms   1849.78ms   1440.31ms  hasherdashery-200a6c732704/lib/hasherdashery/data_type/base.rb
  1416.28ms   1838.26ms    301.43ms  hasherdashery-200a6c732704/lib/hasherdashery/data_type/pattern.rb
   594.30ms    492.44ms    101.86ms  hasherdashery-200a6c732704/lib/hasherdashery/dsl/pattern_maker.rb
   457.08ms    406.78ms     50.31ms  lib/patterns/api/v3/common_patterns.rb
   424.95ms    530.18ms    402.26ms  hasherdashery-200a6c732704/lib/hasherdashery/dsl/common_methods.rb
   311.47ms      0.00ms    311.47ms  lib/api/router.rb
   274.65ms    329.48ms     55.15ms  lib/patterns/api/v3/portal_patterns.rb
   247.06ms    121.02ms    126.04ms  hasherdashery-200a6c732704/lib/hasherdashery/dsl/simple_type_methods.rb
   229.35ms    142.72ms     86.63ms  hasherdashery-200a6c732704/lib/hasherdashery/pattern_rack.rb
   176.25ms    182.78ms    100.57ms  hasherdashery-200a6c732704/lib/hasherdashery/dsl/pin_method.rb
   161.32ms     20.78ms    140.54ms  hasherdashery-200a6c732704/lib/hasherdashery/type_label.rb
   127.24ms      4.97ms    122.27ms  hasherdashery-200a6c732704/lib/hasherdashery/type_universe.rb
    66.29ms      0.00ms     66.29ms  hasherdashery-200a6c732704/lib/hasherdashery/label.rb
```

## Installation

Add this line to your application's Gemfile:

    gem 'railsprof'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install railsprof

## Usage

`bundle exec railsprof` from your Rails root.

```
$ be railsprof
Usage: railsprof [options] [method] /path
    -h, --help                       Show this message
        --version                    Show version
    -v, --verbose                    Run verbosely
    -e, --environment ENV            Environment (defaults to RAILS_ENV)
    -q, --query-param KEY=VAL        Add query paramter (-q key=val {key: "val"}
    -w, --warmups N                  Number of warmup runs on stack, default 1
    -n, --num-runs N                 Number of runs in profiling mode, default 1
    -t, --threshold N                Threshold for file output in millis, default: 0.5
    -d, --directory DIR              Local paths to profile, default: app, lib, config
    -g, --gem GEM                    Gems to profile, default:
```

## Contributing

1. Fork it ( http://github.com/orgsync/railsprof/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
