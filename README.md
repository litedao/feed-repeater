# feed-aggregator
Takes values from 3 different feeds (can be from 3 different feedbases) and returns the median value.

This contract reads values from feeds that implement the Feedbase interface. See: https://github.com/nexusdev/feedbase

If a feedbase address is not set, an exception will be thrown.

If a feed is not set or its value is expired, it will return a value of 0 and false.
