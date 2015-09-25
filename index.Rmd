---
title       : Writing your own URL shortener 
subtitle    : 
author      : Alex Shum
job         : 
framework   : revealjs        # {io2012, html5slides, shower, dzslides, ...}
highlighter : highlight.js  # {highlight.js, prettify, highlight}
hitheme     : tomorrow      # 
widgets     : [mathjax]            # {mathjax, quiz, bootstrap}
mode        : selfcontained # {standalone, draft}
knit        : slidify::knit2slides
---

## Writing your own URL shortener

Alex Shum

September 25, 2015

---

## About Me
<img src="bio-photo.jpg" alt="Drawing" style="width: 250px;"/>

Languages: R, Java, C/C++

Github: www.github.com/ALShum <br/>
URL: www.ALShum.com  <br/>
Twitter: @NotAlexShum

--- &vertical

## URL Shorteners
- Condense regular URL into short form.
- For use with Twitter.
- Also used to monitor traffic.
- http://Bit.ly, http://t.co, http://tinyURL.com

***

## Bitly Example
Start URL:

https://www.youtube.com/watch?v=dQw4w9WgXcQ 

***

## Bitly Example
Short URL:

http://bit.ly/IqT6zt

---

## How to convert long URL to Short
Naive Approach:

1. Hashing the long URL

2. Convert hash integer to base 62

--- &vertical

## Introduction to Hashing
- Hashing function maps arbitrary data type to an integer.
- Often used to map a data type into an index value for a table.

*** 

## Simple hash function
$$latex
f(x) = ax + b \text{ mod } c
$$

Where $$latex a $$ and $$latex c $$ have to be relatively prime.

***

## Example Usage:
```
def hash(input):
	a = 5
	b = 3
	c = 11

	return((a * input + b) % c)
```

***

## Example Usage 2:
When dealing with non-numeric data, there needs to be a way to convert elements to numbers.  For example, characters can be converted to their ASCII values.
```
def hash(char):
	x = ord(char)
	a = 2
	b = 1
	c = 5

	return((a * x + b) % c)
```

***

## Hash Collisions
The problem with hash functions is possibility with collisions.

Two different elements can hash to the same value

```
def hash(input):
	a = 5
	b = 3
	c = 11
	return((a * input + b) % c)

hash(1) # 8
hash(12) # 8
```

--- &vertical

## Cryptographic Hash Functions
- Somewhat similar to simple hash functions.
- Very unlikely to generate hash collisions.
- One way: difficult to calculate the input element given the hash values.

***

## Cryptographic Hash Functions
- MD5, SHA-1
- MD5 returns a 32 digit hexadecimal number.

```
import hashlib
m = hashlib.md5("http://en.wikipedia.org")
m.hexdigest()
#'c8c50bcae456402f5123ea38e124cb3f'
```

*** Cryptographic Hash Functions
Clearly a 32 digit string defeats the purpose of a short URL.

Convert to base 62 and truncate MD5 hash from 32 characters to 6 - 8 characters.

Unfortunately, this greatly increases the probability of a collision.

---

## Math
Mathematically speaking, it's not possible to hash a URL without producing a significant amount of hash collisions.

To see why, look at URL structure:

--- &vertical

## URL Structure
scheme :// [user:pass@] domain [:port] / path [?query] [#fragment]

Scheme: ftp://, http://, https://

***

Domain: http://google.com, http://wikipedia.org, http://github.com

1. case insensitive
2. a - z, 0 - 9, '-'
3. 64 characters long.

***

Path: http://www.wikipedia.org/wiki/Hamtaro

1. case sensitive
2. a - z, A - Z, 0 - 9, '-', '_'
3. no real character limit

***

## How many unique URLs are possible?
Unique Domains: $$latex
37^{64}
$$

Unique URL Paths, Assume 100 character limit:
$$latex
64^{100}
$$

Total:
$$latex
37^{64} * 64^{100}
$$
## 

***

## How many unique shortened URLs are possible?
- Shortened String will be 6 characters.
- Possible characters a - z, A - Z, 0 - 9.
- $$latex
62^6
$$

---

## Reality
Trying to map a MUCH bigger set into a small set.  This is impossible without collisions.

---

## Solutions
Hashing the URLs directly is more work than necessary.

- Most random combination of strings are not valid URLs.

- Most valid URLs will not be inputted into a URL shortening service.

- Only worry about the URLs that have been submitted by a user.

--- &vertical

## Database approach
- Store incoming submitted URLs in database.
- Hash the row ID of URL.
- Only worry about generating shortened URLs for submitted URLs.

***

## Database Structure
```
+--------+--------------+------+-----+---------+----------------+
| Field  | Type         | Null | Key | Default | Extra          |
+--------+--------------+------+-----+---------+----------------+
| id     | bigint(20)   | NO   | PRI | NULL    | auto_increment |
| orig   | varchar(512) | NO   |     | NULL    |                |
| short  | varchar(10)  | NO   |     | NULL    |                |
| visits | bigint(20)   | NO   |     | NULL    |                |
+--------+--------------+------+-----+---------+----------------+
```

---

## Row IDs into Strings
- Can be done without hashing: convert base 10 (Row IDs) to base 62 (lower/upper case plus 0 - 9)
- No longer a one-way function
- Don't want users to be able to guess URLs.
- Don't want users to be able to guess next URLs.
- Don't want bad words to appear in URLs.

---

## Converting from base 10 to base 62
```
def dec_to_base62(x):
	digits = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
	base62 = []
	while(True):
		rem = x % 62
		base62.insert(0, digits[rem])
		x = int(x) / 62
		if(x <= 0):
			break

	return(''.join(base62))
```

Notice that adjacent integers will produce similar strings:

```
dec_to_base62(234) # 3M
dec_to_base62(235) # 3N
```

---

Can make it a bit harder to predict by shuffling the digits string:
```
import random
digits = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
digits = ''.join(random.sample(digits, len(digits)))

def dec_to_base62(x, digits):
	base62 = []
	while(True):
		rem = x % 62
		base62.insert(0, digits[rem])
		x = int(x) / 62
		if(x <= 0):
			break

	return(''.join(base62))
```

A bit harder to predict, but doesn't fully solve close integers generating similar strings:
```
dec_to_base62(234, digits) #pc
dec_to_base62(235, digits) #p3
```

--- &vertical

## Solution

- Combine previous ideas of hashing, shuffling and base 62.
- Start with an alphabet of 62 characters.
- Shuffle alphabet and "randomly" choose letters in alphabet based on your input number.

***

## Encoding Integer to String

```
alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
def _encode(number, alphabet):
    encoded = ''
    len_alphabet = len(alphabet)
    while True:
        encoded = alphabet[number % len_alphabet] + encoded
        number //= len_alphabet
        if not number:
            return encoded
```

***

## Advantages
- Similar idea to hashing but no collisions are possible.
- Can actually reverse the process to decode.

```
def _decode(encoded_str, alphabet):
    number = 0
    len_hash = len(encoded_str)
    len_alphabet = len(alphabet)
    for i, character in enumerate(encoded_str):
        position = alphabet.index(character)
        number += position * len_alphabet ** (len_hash - i - 1)

    return number
```

---

## Hashids
- Turns out someone has thought about this problem and released a library.
- http://hashids.org
- Also encodes integer vectors, and reserves some characters as separators so it prevents the possibility of swear words.
- http://hashids.org/r/

```
from hashids import Hashids
hashids = Hashids(salt="salt string")
id = hashids.encode(1, 2, 3) #'8bUkTP'
numbers = hashids.decode(id) #(1,2,3)
```

---

## Other issues for URL shorteners:
- Linking to malicious sites.
- Need a quick way to check if submitted URLs are malicious links.
- Filter javascript.
- Need fast lookup to check sites: bloom filters.

--- 

## END
<img src="Ice_King.png" alt="Drawing" style="width: 250px;"/>
