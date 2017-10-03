library(httr)
library(tm)

library(ggplot2)
library(RColorBrewer)
library(wordcloud)
library(twitteR)
library(tm.plugin.webmining)

library(NLP)
library(openNLP)
library(qdap)
library(qdapTools)
library(qdapDictionaries)
library(qdapRegex)
library("doBy")
## Loading required package: survival
oauth_endpoints("twitter")
## <oauth_endpoint>
##  request:   https://api.twitter.com/oauth/request_token
##  authorize: https://api.twitter.com/oauth/authenticate
##  access:    https://api.twitter.com/oauth/access_token
#consumer_key ="your consumer key"
#consumer_secret="your consumer secret"
#access_token="your access token"
#access_token_secret="your access token secret"
setup_twitter_oauth("Dll8rlF5lEgwDjExVjYjJZ2H1","vXBT3j2qfWzvnwrOCcQewhxdPWZjceTQOFfgSwiJjRXL6LwF6h","795653678959128577-groWsbL1jY7WGaLYl4fjooTvMOaTlwT","TJvRII0aKHpl594pQ8CgNNon6yEIg27PBJOtZi8ow5SLA")
## [1] "Using direct authentication"
##delta tweets
delta.tweets = searchTwitter('@delta', n=500)
tweet = delta.tweets[[1]]
#tweet$getScreenName()


#convert list to array output
library(plyr)

delta.text = laply(delta.tweets, function(t) t$getText() )
head(delta.text, 5)
##[1] "Great job, @Delta. Shame on you, @FlyFrontier. https://t.co/iXPp7iEHKH"                                                           
##[2] "@Delta Boeing 757 , charter of the @BuffaloSabres of the @NHL https://t.co/Vv2Hn2wWDn  Parked in Ottawa @FlyYOW"                  
##[3] "@Delta How can I get reimbursed for toiletries and something to wear so I don't freeze in Czech while waiting on my delayed bags?"
##[4] "@Delta they got me a seat. Not impressed in the least with the customer service at the gate at ATL."                              
##[5] "@gamerwhomgame @Delta"
hu.liu.pos = scan('H:/DICT/positive-words.txt',what='character',comment.char=';')
hu.liu.neg = scan('H:/DICT/negative-words.txt', what='character', comment.char=';')

##update the positive words and negative words
pos.words = c(hu.liu.pos , 'upgrade')
neg.words = c(hu.liu.neg , 'wtf','waiting' ,'wait' ,'epicfail' ,'mechanical')

sample = c("You're awesome and I love you", "I hate and hate and hate. So angry. Die!","Impressed and amazed: you are peerless in your achievement of unparalleled mediocrity.")

score.sentiment = function(sentences, pos.words, neg.words, .progress='none')
{
  require(plyr)
  require(stringr)
  # we got a vector of sentences. plyr will handle a list
  # or a vector as an "l" for us
  # we want a simple array of scores back, so we use
  # "l" + "a" + "ply" = "laply":
  scores = laply(sentences, function(sentence, pos.words, neg.words) {
    # clean up sentences with R's regex-driven global substitute, gsub():
    sentence = gsub('[[:punct:]]', '', sentence)
    sentence = gsub('[[:cntrl:]]', '', sentence)
    sentence = gsub('\\d+', '', sentence)
    # and convert to lower case:
    sentence = tolower(sentence)
    # split into words. str_split is in the stringr package
    word.list = str_split(sentence, '\\s+')
    
    # sometimes a list() is one level of hierarchy too much
    words = unlist(word.list)
    # compare our words to the dictionaries of positive & negative terms
    pos.matches = match(words, pos.words)
    neg.matches = match(words, neg.words)
    # match() returns the position of the matched term or NA
    # we just want a TRUE/FALSE:
    pos.matches = !is.na(pos.matches)
    neg.matches = !is.na(neg.matches)
    # and conveniently enough, TRUE/FALSE will be treated as 1/0 by sum():
    score = sum(pos.matches) - sum(neg.matches)
    return(score)
  }, pos.words, neg.words, .progress=.progress )
  scores.df = data.frame(score=scores, text=sentences)
  return(scores.df)
}
##output for the sample
result = score.sentiment(sample, pos.words, neg.words)
## Loading required package: stringr
##cleaning the data
delta.text=str_replace_all(delta.text,"[^[:graph:]]", " ")


# calculate the scores

delta.scores = score.sentiment(delta.text, pos.words,neg.words)

#adding two columns
delta.scores$airline = 'Delta'
delta.scores$code = 'DL'



##plotting
qplot(delta.scores$score)
american.tweets = searchTwitter('@AmericanAir', n=500)
american.text = laply(american.tweets, function(t) t$getText() )
american.text=str_replace_all(american.text,"[^[:graph:]]", " ")


american.scores = score.sentiment(american.text, pos.words,neg.words)

american.scores$airline = 'American'
american.scores$code = 'AA'

#@united


united.tweets = searchTwitter('@united', n=500)
united.text = laply(united.tweets, function(t) t$getText() )
united.text=str_replace_all(united.text,"[^[:graph:]]", " ")
united.scores = score.sentiment(united.text, pos.words,neg.words)
united.scores$airline = 'United'
united.scores$code = 'UA'



#@JetBlue
jetblue.tweets = searchTwitter('@JetBlue', n=500)
jetblue.text = laply(jetblue.tweets, function(t) t$getText() )
jetblue.text=str_replace_all(jetblue.text,"[^[:graph:]]", " ")
jetblue.scores = score.sentiment(jetblue.text, pos.words,neg.words)
jetblue.scores$airline = 'JetBlue'
jetblue.scores$code = 'JB'

#@SouthwestAir

southwest.tweets = searchTwitter('@SouthwestAir', n=500)
southwest.text = laply(southwest.tweets, function(t) t$getText() )
southwest.text=str_replace_all(southwest.text,"[^[:graph:]]", " ")
southwest.scores = score.sentiment(southwest.text, pos.words,neg.words)
southwest.scores$airline = 'Southwest'
southwest.scores$code = 'SA'


#combine all scores

all.scores = rbind( delta.scores,american.scores,united.scores, jetblue.scores, southwest.scores )


##positive and negative tweets

all.scores$very.pos = as.numeric( all.scores$score >= 2 )
all.scores$very.neg = as.numeric( all.scores$score <=- 2 )
all.scores$very.neu = as.numeric(all.scores$score == 0)
##overall sentiment score is positive/negative
twitter.df = ddply(all.scores, c('airline', 'code'), summarise, pos.count = sum( very.pos ), neg.count = sum( very.neg ), neu.count=(sum(very.neu)) )
twitter.df$all.count = twitter.df$pos.count + twitter.df$neg.count + twitter.df$neu.count
twitter.df$score = round( 100 * twitter.df$pos.count /twitter.df$all.count )
twitter1.df <- t(twitter.df)
colnames(twitter1.df) <- twitter1.df[1,]


twitter1.df <- twitter1.df[2:nrow(twitter1.df),]



#plotting for all scores

cbPalette=c("#a6cee3","#1f78b4",
            "#b2df8a",
            "#33a02c",
            "#fb9a99")



ggplot(data=all.scores) +  geom_histogram(mapping=aes(x=score, fill=airline), binwidth=1) + facet_grid(airline~.) +  theme_bw() + scale_fill_manual(values=cbPalette)

orderBy(~-score, twitter.df)
## Plotting Pie chart for positive, negative and neutral.
twitter1 <- read.csv(file = "data.csv")
Southwest = ggplot(twitter1) + aes(x=factor(1), y= twitter1$Southwest, fill=twitter1$group) +
  geom_bar(stat="identity") +
  coord_polar("y") +
  theme(axis.text.x=element_text(color="black")) + theme_void()
Southwest
American = ggplot(twitter1) + aes(x=factor(1), y= twitter1$American, fill=twitter1$group) +
  geom_bar(stat="identity") +
  coord_polar("y") +
  theme(axis.text.x=element_text(color="black")) + theme_void()
American
Delta = ggplot(twitter1) + aes(x=factor(1), y= twitter1$Delta, fill=twitter1$group) +
  geom_bar(stat="identity") +
  coord_polar("y") +
  theme(axis.text.x=element_text(color="black")) + theme_void()
Delta
JetBlue = ggplot(twitter1) + aes(x=factor(1), y= twitter1$JetBlue, fill=twitter1$group) +
  geom_bar(stat="identity") +
  coord_polar("y") +
  theme(axis.text.x=element_text(color="black")) + theme_void()
JetBlue
United = ggplot(twitter1) + aes(x=factor(1), y= twitter1$United, fill=twitter1$group) +
  geom_bar(stat="identity") +
  coord_polar("y") +
  theme(axis.text.x=element_text(color="black")) + theme_void()
United
