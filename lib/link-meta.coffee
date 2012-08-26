http = require 'http'
url = require 'url'
oembed = require 'oembed'
async = require 'async'

oembed.EMBEDLY_KEY = config.get('oembed:embedly_key')

SCHEME = "[a-z\\d.-]+://"
IPV4 = "(?:(?:[0-9]|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])\\.){3}(?:[0-9]|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])"
HOSTNAME = "(?:(?:[^\\s!@#$%^&*()_=+[\\]{}\\\\|;:'\",.<>/?]+)\\.)+"
TLD = "(?:ac|ad|aero|ae|af|ag|ai|al|am|an|ao|aq|arpa|ar|asia|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|biz|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|cat|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|coop|com|co|cr|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|edu|ee|eg|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gov|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|info|int|in|io|iq|ir|is|it|je|jm|jobs|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mil|mk|ml|mm|mn|mobi|mo|mp|mq|mr|ms|mt|museum|mu|mv|mw|mx|my|mz|name|na|nc|net|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|org|pa|pe|pf|pg|ph|pk|pl|pm|pn|pro|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tel|tf|tg|th|tj|tk|tl|tm|tn|to|tp|travel|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|xn--0zwm56d|xn--11b5bs3a9aj6g|xn--80akhbyknj4f|xn--9t4b11yi5a|xn--deba0ad|xn--g6w251d|xn--hgbk6aj7f53bba|xn--hlcj6aya9esc7a|xn--jxalpdlp|xn--kgbechtv|xn--zckzah|ye|yt|yu|za|zm|zw)"
HOST_OR_IP = "(?:" + HOSTNAME + TLD + "|" + IPV4 + ")"
PATH = "(?:[;/][^#?<>\\s]*)?"
QUERY_FRAG = "(?:\\?[^#<>\\s]*)?(?:#[^<>\\s]*)?"
URI1 = "\\b" + SCHEME + "[^<>\\s]+"
URI2 = "\\b" + HOST_OR_IP + PATH + QUERY_FRAG + "(?!\\w)"
MAILTO = "mailto:"
EMAIL = "(?:" + MAILTO + ")?[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@" + HOST_OR_IP + QUERY_FRAG + "(?!\\w)"
URI_RE = new RegExp( "(?:" + URI1 + "|" + URI2 + "|" + EMAIL + ")", "ig" )

class LinkMeta
  constructor: (@link) ->
    @url = url.parse(@link)

  meta: (done) ->
    methods = [
      (done) => @isImage(done)
      (done) => @isOembed(done)
    ]

    async.parallel methods, (error, results) ->
      if error
        done(error)
      else
        merged = {}
        for result in results
          for key, value of result
            merged[key] = value
        done(null, merged)

  isImage: (done) ->
    options =
      method: 'HEAD'
      path: @url.pathname
      host: @url.host
      port: @url.port || 80

    req = http.request options, (response) ->
      response.setEncoding('utf8')
      if type = response.headers['content-type']
        type = type.split(";")[0]
        done(null, image: !!type.match(/image/))
      else
        console.log "no"
        done(null, image: no)

    req.on 'error', -> done(null, image: no)
    req.end()

  isOembed: (done) ->
    oembed.fetch @link, maxwidth: 1920, (error, result) ->
      if error
        done(null, oembed: no)
      else if result
        done(null, oembed: result)

module.exports =
  fetch: (link, callback) -> new LinkMeta(link).meta(callback)
  findLinks: (text) -> (text || "").match(URI_RE) || []
