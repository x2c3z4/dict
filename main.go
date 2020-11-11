package main

import (
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"

	"github.com/PuerkitoBio/goquery"
)

const URL = "http://cn.bing.com/dict/search?q=%s&FORM=BDVSP6&mkt=zh-cn"

type Bing struct {
	key string
	doc *goquery.Document
}

func (b *Bing) GetUrl(key string) string {
	key = url.QueryEscape(key)
	return fmt.Sprintf(URL, key)
}

func (b *Bing) Parse() {
	url := b.GetUrl(b.key)
	// Request the HTML page.
	res, err := http.Get(url)
	if err != nil {
		log.Fatal(err)
	}
	defer res.Body.Close()
	if res.StatusCode != 200 {
		log.Fatalf("status code error: %d %s", res.StatusCode, res.Status)
	}

	// Load the HTML document
	doc, err := goquery.NewDocumentFromReader(res.Body)
	if err != nil {
		log.Fatal(err)
	}
	b.doc = doc
	b.ParseVoice()
	b.ParseMeaning()
	b.ParseVar()
	b.ParseSameWord()
	b.ParseEC()
	b.ParseEE()
}

func (b *Bing) ParseVoice() {
	prUS := b.doc.Find(".lf_area .qdef .hd_p1_1 .hd_prUS").Text()
	pr := b.doc.Find(".lf_area .qdef .hd_p1_1 .hd_pr").Text()
	fmt.Printf("%s %s\n", prUS, pr)
	fmt.Println()
}

func (b *Bing) ParseMeaning() {
	b.doc.Find(".lf_area .qdef ").Find("li").Each(func(i int, s *goquery.Selection) {
		fmt.Printf("%6s: ", s.Find("span[class=pos]").Text())
		fmt.Printf("%s\n", s.Find("span[class='def b_regtxt']").Text())
	})
	fmt.Println()
}

func (b *Bing) ParseVar() {
	b.doc.Find(".lf_area .qdef .hd_div1 .hd_if").Each(func(i int, s *goquery.Selection) {
		sel1 := s.Find("span")
		sel2 := s.Find("a")
		for j := range sel1.Nodes {
			single1 := sel1.Eq(j)
			single2 := sel2.Eq(j)
			fmt.Printf("%s %s ", single1.Text(), single2.Text())
		}
	})
	fmt.Println()
}
func (b *Bing) ParseSameWord() {
	//fmt.Printf("%s: ", b.doc.Find("#synotabid > h2").Text())
	fmt.Printf("同义词:")
	b.doc.Find(".lf_area .qdef .wd_div .col_fl").Find("span").Each(func(i int, s *goquery.Selection) {
		fmt.Printf("%s", s.Text())
	})
	fmt.Println()
	fmt.Println()
}

func (b *Bing) ParseEC() {
	fmt.Println("E-C：")
	b.doc.Find(
		"#crossid > table > tbody > tr > td:nth-child(2) > div",
	).Find(
		"span",
	).Each(
		func(i int, s *goquery.Selection) {
			fmt.Printf("%d: %s\n", i+1, s.Text())
		},
	)
	fmt.Println()
}

// https://www.flysnow.org/2018/01/20/golang-goquery-examples-selector.html
func (b *Bing) ParseEE() {
	fmt.Println("E-E：")
	b.doc.Find(
		"#homoid > table > tbody > tr > td:nth-child(2) > div",
	).Find("div[class=df_cr_w]").Each(
		func(i int, s *goquery.Selection) {
			fmt.Printf("%d: %s\n", i+1, s.Text())
		},
	)
	fmt.Println()
}

func NewBing(key string) *Bing {
	return &Bing{
		key: key,
	}
}

func main() {
	if len(os.Args) != 2 {
		fmt.Println("please enter your word")
		os.Exit(1)
	}
	key := os.Args[1]
	b := NewBing(key)
	b.Parse()
}
