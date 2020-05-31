from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.options import Options
import time
import os
import re
from bs4 import BeautifulSoup
import json


class AJIOScraper():
    def scroll(self, driver, timeout):
        scroll_pause_time = timeout
        # Get scroll height
        last_height = driver.execute_script("return document.body.scrollHeight")
        while True:
            # Scroll down to bottom
            driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            # Wait to load page
            time.sleep(scroll_pause_time)
            # Calculate new scroll height and compare with last scroll height
            new_height = driver.execute_script("return document.body.scrollHeight")
            if new_height == last_height:
                # If heights are the same it will exit the function
                break
            last_height = new_height

    def get_product(self, url):
        options = Options()
        # options.headless = True
        profile = webdriver.FirefoxProfile()
        # profile.set_preference("permissions.default.image", 2)
        driver = webdriver.Firefox(firefox_profile=profile, options=options)
        JSON = {}
        iii = -1
        for URL in url:
            iii = iii + 1
            try:
                driver.get(URL)
                soup = BeautifulSoup(driver.page_source, "html.parser")
                Category = soup.select("ul[class=breadcrumb-sec] li[class=breadcrumb-list]")[3].getText()
                Gender = soup.select("ul[class=breadcrumb-sec] li[class=breadcrumb-list]")[1].getText()
                BrandName = soup.select_one("div[class=prod-content] [class=brand-name]").getText()
                ProductName = soup.select_one("div[class=prod-content] [class=prod-name]").getText()
                if len(soup.select("div[class=prod-content] [class=prod-cp]")):
                    MRP = int(
                        (soup.select_one("div[class=prod-content] [class=prod-cp]").getText())[4:].replace(",", ""))
                    Discount = int((MRP - int(
                        (soup.select_one("div[class=prod-content] [class=prod-sp]").getText())[4:].replace(",",
                                                                                                           ""))) / MRP * 100)
                else:
                    Discount = 0
                    MRP = 0
                DescriptionList = soup.select("[class=prod-desc] [class=detail-list]")
                Description = ''
                PID = DescriptionList[-1].getText()
                for i in DescriptionList[:-1]:
                    Description += i.getText() + ";;"
                ImgSrc = list(set([i.get("src") for i in
                                   soup.select(
                                       "div[class=slick-list] div[class=slick-track] div[class=img-container] img")]))
                Size = [i.getText() for i in soup.select("[class=size-swatch] div")]
                if(len(Size)==0):
                    print(Size)
                    Size = [i.getText() for i in soup.select("div[class=size-variant-block] [class=slick-track]>div>div")]
                    print(Size)
                JSON[iii] = [BrandName, ProductName, MRP, Discount, Description, ImgSrc, Size, PID, Gender, Category]
            except:
                pass
        with open('products.json', 'w') as fp:
            json.dump(JSON, fp)
        driver.close()


s = AJIOScraper()
productURL = []
with open('productURL.txt', 'r')as fp:
    productURL = [i.replace("\n", "") for i in (fp.readlines())]
s.get_product(productURL[:])
