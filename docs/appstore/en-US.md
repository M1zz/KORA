# App Store 메타데이터 — English (U.S.) (en-US)

App Store Connect 현지화: **English (U.S.) (en-US)** · 버전 1.0.5

각 값은 코드 블록 안의 텍스트를 그대로 복사해 붙여 넣는다. 글자 수는 Python `len()`으로 검증했다.


## Name

chars: **28** / limit 30

홈 화면 이름(CFBundleDisplayName)과 별개. App Store 이름은 스토어 전체에서 고유해야 하므로, 이미 쓰이고 있으면 아래 대체안을 쓴다.

```
KORA: Korea Subway Navigator
```

## Name (fallback)

chars: **28** / limit 30

```
KORA - Korea Metro Wayfinder
```

## Subtitle

chars: **30** / limit 30

```
Seoul Metro Guide for Visitors
```

## Promotional Text

chars: **135** / limit 170

버전 심사 없이 언제든 바꿀 수 있는 칸.

```
Board the right train and never miss your stop. KORA is now one simple screen and speaks five languages, including Traditional Chinese.
```

## Description

chars: **2426** / limit 4000

평문. 마크다운 기호 없음.

```
KORA is a subway guide for anyone visiting Korea.
Choose your starting station and destination, and KORA shows the transfers, number of stops, estimated time, and which direction to board, exactly as the train's "To ○○" sign reads. While you ride, it follows your current station and tells you when to get off.

YOUR STATION, FOUND FOR YOU
Find the nearest station with GPS or pick one yourself. KORA remembers it the next time you open the app.

ROUTE AND BOARDING DIRECTION
See transfers, stops and estimated travel time, plus the train to take, shown as its "To ○○" destination sign. You get a heads-up when the last train is near.

CHECK THE DIRECTION WITH YOUR CAMERA
Point your camera at the platform sign or the train's destination display and KORA tells you right away whether it's the right way. Text recognition happens entirely on your iPhone.

KNOW WHERE YOU ARE
KORA combines Seoul's real-time arrival data, GPS, the accelerometer (to sense departures and stops) and on-device recognition of the in-train announcements to track your current station. It even tells you which side the doors will open.

STOP ALERTS
As your stop approaches you get "Prepare to get off", then "Get off now", with haptics. A progress diagram shows the train and a pin on your destination.

LOCK SCREEN AND DYNAMIC ISLAND
A Live Activity keeps your ride progress visible without unlocking your phone.

FIVE LANGUAGES
Station names appear in Korean, Japanese (katakana), English and Chinese. Switch the whole app between Korean, Japanese, English, Simplified Chinese and Traditional Chinese. It starts in your phone's language.

COVERAGE
About 930 stations in the Seoul metropolitan area (Seoul, Gyeonggi and Incheon, including GTX-A, AREX, the Shinbundang Line and light rail lines), Busan, Daegu, Gwangju and Daejeon. Switch cities with the region chips in the station picker.

WORKS OFFLINE
Routes are calculated on your device, so route search works without internet. Only real-time arrivals need a connection.

PRIVATE BY DESIGN
No account, no ads, no in-app purchases. Location, camera and announcement recognition are processed on your device and are never stored or sent anywhere. We only collect anonymous usage statistics to improve the app.

Camera, microphone, speech recognition and motion access are all optional. Without them you can still pick stations yourself and get full route guidance.

Contact: mizzking75@gmail.com
```

## Keywords

chars: **96** / limit 100

14개 키워드, 쉼표 뒤 공백 없음. 이름·부제에 이미 들어간 단어는 뺐다. 경쟁 앱 상표 없음.

```
busan,incheon,daegu,daejeon,gwangju,gtx,arex,airport,train,transfer,route,station,travel,tourist
```

## Support URL

```
https://m1zz.github.io/KORA/en/support.html
```

## Marketing URL

```
https://m1zz.github.io/KORA/en/
```

## Privacy Policy URL

```
https://m1zz.github.io/KORA/en/privacy.html
```

## What's New in This Version (1.0.5)

chars: **483** / limit 4000

RELEASE_NOTES.md 의 같은 언어 절과 동일.

```
KORA is now a single screen focused on subway guidance, without tabs or the map
While riding, the station you get off at now shows a pin so your destination is easy to spot
Closing the app now also ends the Live Activity on the Lock Screen
Added Traditional Chinese, and the whole app is now available in English, Japanese and Simplified Chinese
Fixed platform sign scanning sometimes marking the next station as the wrong direction, and long station names being cut off while riding
```

## 키워드 메모

이름·부제에 있는 단어(kora, korea, subway, navigator, seoul, metro, guide, visitors)는 App Store가 이름·부제·키워드를 합쳐 색인하므로 키워드에서 뺐다. 복수형은 Apple이 알아서 매칭하므로 단수만 넣었다. 경쟁 앱 이름은 쓰지 않았다.
