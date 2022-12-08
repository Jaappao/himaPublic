# hima
今ひまかどうかしかわからないSNS「hima?」

![https://www.dropbox.com/s/882s5lj11q3vufu/hima_mainvisual.png?raw=1](https://www.dropbox.com/s/882s5lj11q3vufu/hima_mainvisual.png?raw=1)

## 概要
自分がフォローしている友人が、今暇かどうかを確認できる。
自分が暇だと感じた時にスイッチをOnにしておくと、それを見た友人が連絡をとって連絡をしてくるかもしれない。暇な友人がいれば、連絡を取り合って、暇を潰そう。

## 作業期間
1ヶ月

## 関係者の人数
2人

## 担当役割
要件定義〜実装

※ もう一人の関係者とは Code Reviewと非同期処理に関する相談をした。

## 開発言語・技術
Swift、Firebase（主にAuthenticator, Firestore, Storage）

## 参考URL（スクリーンキャプチャ動画等）
https://www.dropbox.com/sh/70uymolpsmxf3um/AABIAcKRf8fXpO1PkvQVdmtBa?dl=0

## きっかけ
コロナ禍で友人とのつながりが薄れた時期に、コミュニケーションのきっかけを作るために、友人が暇かどうかがわかるアプリケーションがあれば、気軽に連絡を取ることができると思い開発に至った。
また、コロナ禍で時間の余裕が生まれたため、技術的なチャレンジをしたいと思い、初めてのiOSアプリケーション開発に取り組もうと思った。

## アピールポイント
操作するスイッチを大きく配置し、一目で見て操作の仕方がわかるようなUIを目指した。見知らぬ人から勝手にフォローされることを防止するために、フォローする際にはパスワードを必要とした。

本アプリは AppStore にリリースした。（現在はメンテナンスをしていないため、Storeに出ていない。）

## Future Work
- 自発的にスイッチをOnにするという行為が、ユーザーにとっては負担が大きいため、負担のない形で暇かどうかを共有できるのが望ましい。
- 現時点ではページを開くたびにFirestoreにアクセスして最新の情報をFetchしているが、Snapshot Listenerを使うことで、サーバー側の変更をクライアントで自動で反映できる。 それを使って、他の人の暇かどうかの状態の更新をするのが望ましい。



