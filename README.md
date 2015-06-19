# atom-twitter package

Twitter client for Atom.

![A screenshot of your package](https://raw.githubusercontent.com/p-baleine/atom-twitter/master/screenshot.png)

## Installation

```bash
$ git clone https://github.com/p-baleine/atom-twitter.git ~/.atom/packages/atom-twitter
$ cd ~/.atom/packages/atom-twitter && apm install
```

### TODO  

Register this package to atom.io.

```bash
$ # apm install atom-twitter
```

## Settings

Create your [twitter application](https://apps.twitter.com/) and set `consumerKey`, `consumerSecret`, `accessToken` and `accessTokenSecret`.

```bash
"atom-twitter":
  "consumerKey": "your consumer key"
  "consumerSecret": "your consumer secret"
  "accessToken": "your access token"
  "accessTokenSecret": "your access token secret"
```

## Usage

### Home timeline

[Packages] -> [Twitter] -> [Home]

### Search

[Packages] -> [Twitter] -> [Search], then enter the keyword.

## TODO

* link in status
* README
* Travis?
* task
* retry parse delimited count
* connection status
