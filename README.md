# EKS-sample
create CI/CD pipeline using codepipeline and EKS

#kubectlをインストール

kubectlがインストールされているか確認
```
kubectl version | grep Client | cut -d : -f 5 
```
こんな感じの表示が出たらOK
```
#"v1.22.6-eks-7d68063", GitCommit
```

# kubectolをAWS経由でインストール
S3バケットにkubectlのインストーラが公開されている
[リンク](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/install-kubectl.html)


*clusterはeksctlコマンドで一発で作成可能
```
eksctl create cluster
```
- EKS ControlPlane
- VPC, InternetGateway, route table, subnet, EIP, NAT Gateway, security group
- IAM Role, Policynode group, Worker node（EC2）
- 〜/.kube/config

が作られる


# チュートリアルに沿ってEKS用のVPC作成
VPC(Vertual Private Cloud)：IAMユーザが作成でき、作成したアカウントからアクセス可能な仮想ネットワーク

EKSを利用するにはVPCとして必要な要件がある
- サブネットには、それぞれ 6 個以上の IP アドレスが必要(IP アドレスは 16 個以上を推奨)
- サブネットは AWS Outposts、AWS Wavelength、または AWS ローカルゾーンに存在することはできない。ただし、VPC 内にサブネットが存在する場合は、セルフマネージド型ノード および Kubernetes のリソースをこれらのタイプのサブネットにデプロイ可能。
- サブネットでは IP アドレスベースの命名を使用する必要があります。Amazon EC2 のリソースベースの命名は、Amazon EKS でサポートされていません。
- サブネットは、パブリックでもプライベートでもOK。推奨は、プライベートサブネット指定。


# kubenetesクラスタの作成
## kubenetes用語メモ
クラスタ：コンテナ化されたアプリケーションを実行するためのノードマシン(コンピューティングリソース)群

- コントロールプレーン：Kubernetes ノードを制御する一連のプロセス。すべてのタスクの割り当てはここで発生します。

- ノード：要求に基づいてコントロールプレーンによって割り当てられたタスクを実行するマシン。

- Pod：1 つのノードにデプロイされた、1 つ以上のコンテナのセット。ポッドは、最小かつ最も単純な Kubernetes オブジェクトです。

- サービス： 一連のポッドで実行されているアプリケーションをネットワークサービスとして公開する方法。ポッドから作業の定義を分離します。

- ボリューム：ポッド内のコンテナにアクセスできるデータを含むディレクトリ。Kubernetes ボリュームの寿命は、それを包含するポッドと同じです。ボリュームは、ポッド内で実行されるどのコンテナよりも長く存続し、コンテナが再起動してもデータは保持されます。

- 名前空間：仮想クラスタ。名前空間により、Kubernetes は同じ物理クラスタ内の (複数のチームまたはプロジェクトの) 複数のクラスタを管理できます。

[Redhat説明より](https://www.redhat.com/ja/topics/containers/what-is-a-kubernetes-cluster)

## クラスタを作成
[チュートリアルリンク](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/create-cluster.html)

## IAMロールを作成
EKSが他のAWSリソースを制御できるようにIAMロールを作成する

信頼ポリシーを以下のように設定
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
これは、ざっくりいうと「このロールはEKSにつけることができるよ」ということ。

あとは、このロールが実行できる権限を与える
- AmazonEKSServicePolicy

<b>EKS</b>がkubenetesクラスターを作成～運用するためのポリシー
- AmazonEKSClusterPolicy

<b>kubenetesクラスタのコントロールプレーン</b>がAWSリソースを操作するためのポリシー


*AWSサービスが他のサービス操作するとき、被操作対象を操作できる権限を付与したIAMロールを操作する側に付与することが多い(これにより、IAMロールが一時認証トークンになり、認証情報をEC2などに埋め込む必要がなくなる)

## コンソールからクラスタ設定
設定項目
- 名前

IAMユーザで一意にする必要あり
- kubenetesバージョン

自身の環境のkubenetesの1つ前のマーナーバージョンか、それ以上のバージョン(1.22なら1.21以降)を利用できる
- クラスターサービスロール
先程作成したIAMロール

- VPC及びサブネット

先ほど作成したものを選択
- セキュリティグループ

EKSに適用されるIPアドレス許可リスト

EKSクラスタとVPCの通信を許可するグループを自動で追加してくれる

- IPアドレスレンジ
kubenetesが使用するIPアドレスの範囲を指定できる

10.0.0.0/8、172.16.0.0/12、または 192.168.0.0/16 のいずれかの範囲内にある。
(private IP adressのレンジ)

最小サイズが /24、最大サイズが /12。

Amazon EKS リソースの VPC の範囲と重複しない

- クラスターエンドポイントアクセス

クラスタとの通信にネットワークを中継するかどうか


## CLIを利用してクラスタに接続

CLIでログイン
```bash
#Access key IDとSecret access key, region, output(defaultはjson)を設定
aws configure --profile $IAM_NAME
```
ユーザ切り替え
```bash
#オプションで--profileを付ける(一時的)
aws s3 ls --profile $IAM_NAME
#環境変数で切り替える
export AWS_DEFAULT_PROFILE=$IAM_NAME
```

ローカルでAWS上に作成したクラスタを操作可能にするためにconfigを設定
```bash
aws eks update-kubeconfig --region ap-northeast-1 --name EKS-test
```
所定の場所にconfigファイルが生成されていることを確認
```
cat ~/.kube/config
```
AWS上に展開されているクラスタのサービス(？？)の状態を確認
```
kubectl get service
```

## ノードの作成
ノードグループを作成する

### マネージドで実施する場合(EC2)
ノードグループにIAMロールを割り当てる

ノードグループ内では実際にはEC2が動作するため、EC2を信頼ポリシーに追加
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
- AmazonEC2ContainerRegistryReadOnly

ECR参照用
- AmazonEKSWorkerNodePolicy

ワーカーノードからのEKSクラスターアクセス用
- AmazonEKS_CNI_Policy

ノードグループを追加
- ノードIAMロール

先程作成したEC2用のIAMロール
- ノードグループのスケーリング設定

(Auto scallingのようなもの)
- ノードグループの更新設定

バージョンアップ中の利用不可能最大許容数

### アンマネージドで実施する場合(fargate)


## Dockerfileの設定
チェックできれば良いのでシンプルにアパッチを導入

index.htmlを見れるようにしてある


## 作成したDockerのimageをAWSにアップロード
アップロード先としてECR(Elastic Container Registry)を利用

コンソールのレジストリの作成からプライベートリポジトリを作成
*リポジトリ：同じ名前のDocker imageの集まり

- 可視性設定

プライベートに設定

(AWS内の自分のみの利用に留める)
- タグのイミュータビリティ

タグの上書きを防止する(同じタグではimageをpushできなくなる)

### 作成したプライベートリポジトリにアップロード
作成したリポジトリにログイン
```
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${region}.amazonaws.com
```

作成したリポジトリにアップロードできるようにタグを編集
```
docker tag ${image_name} ${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${my-repository}:${tag}
```

ECRにimageをpush
```
docker push ${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${my-repository}:${tag}
```
*コンソールのpushコマンド表示をコピペすれば良い

### codecommitの設定
<!-- リポジトリの作成
- Amazon CodeGuru Reviewer for Java and Python

JavaとPythonのコードレビューを自動で行ってくれる -->

## codeBuildの設定(Build1分あたりに課金)
ビルドプロジェクトを作成する
- ソース
githubを選択、認証して対象のリポジトリを選択

- プライマリーソースのウェブフックイベント

githubのどのイベント、どのブランチを使うかを設定

ACTOR_ID：誰が行った動作かを限定することができる

BASE_REF：refs/heads/${branch_name}で使用するブランチを決定できる

ソースコード内のbuildspec.yamlファイルを探してbuildを実行してくれる

buildspec.yaml
```yaml
version: 0.2

#envはコンソール上で埋め込む方が良い
#より適切なのは、KMS等を利用してアカウントIDを隠すこと
env:
  variables:
    AWS_ACCOUNT_ID: [$AWS_account_id]
    AWS_DEEFAULT_REGION: ap-northeast-1
    IMAGE_REPO_NAME: eks-private-repository

phases:
  prebuild:
    commands:
      - echo login ECR
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.AWS_DEFAULT_REGION.amazonaws.com
      - export IMAGE_TAG="v1"
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image
      - cd $CODEBUILD_SRC_DIR/ #接続したgithubのディレクトリ構造
      - docker build -t $IMAGE_REPO_NAME .
      - docker tag eks-private-repository:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:latest
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
      - echo Push completed on `date`
```

- アーティファクト

buildした結果を保存する先

- ロールの作成

ECRにアクセスできる権限をcodebuildに付与する必要がある

デフォルトで作成されたロールに追記
```json
    {
        "Action": [
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart"
        ],
        "Resource": "*",
        "Effect": "Allow"
    }
```

buildを実行して確認


## codeDeployの設定


残り
- EKS+Codepipelineで変更できるか確認
- 構成図の画像作成