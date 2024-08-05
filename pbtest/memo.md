# pbtest

## 問題
- なんで相対パスでprotofileが指定できないんだ?
  - これは何が悪いんだろ。juliaのノートブックみたいなやつが悪いのか?

- Juliaの通常のシリアライズフォーマットには何が入っててこんなに重いんだ?
  - よくわからないが一声8バイトのヘッダがつくらしい。
    - 37 4a 4c 0f 04 00 00 00
  - 文字列の場合は、`abcde` だと 21 05 61 62 63 64 65  となる。
    - 21 が多分型情報。05 は長さ。
  - Int64を指定しても8バイト増えないのも以外。しかもなんか変なところのビットが立ってるように見える。
    - Int64(1)  で e0 
    - Int64(-1) で 31 ff ff ff ff 
    - 何だこれ? なんでそうなる?というかなぜ-1で8バイトにならんの?
  - Int32だと?
    - Int64(0)  で be 
    - Int64(1)  で bf 
    - Int64(2)  で c0 
    - Int64(-1) で 06 ff ff ff ff 
    - Int64(-2) で 06 fe ff ff ff 

-  https://github.com/JuliaLang/julia/blob/master/stdlib/Serialization/src/Serialization.jl

  これをみたら色々わかった。
  - 8バイトのヘッダは、バージョンやらエンディアンやら。省略可能。
  - Int64 とかの場合は、サイズを見て小さい値の場合はタグと値をORしている。なんとも気持ち悪いが。。
  - これはおそらくProtocolBufferでも同じことをやってるはず。


- まずやりたいのは比較
  - シリアライズ機能 おそらくループや自己参照が扱えないし、ネストした型も扱えない
  - 速度
  - サイズ


- ネストしたオブジェクトのチェック。
- 複数の型のEnumみたいなやつは?
   oneof でできる。OneOf という型がUnion で生成される。すごい。

- 速度は、小さいデータだとかなりPBが速い。1桁速い感じ。
  - が、double 1000個とかだと変わらない。いずれも2.5マイクロぐらい。
  - データ量もほぼ変わらんな。あれー??
  - メモリ使用量が逆転してるかも。うーん。


ProtoBuf
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  284.250 μs …   2.424 ms  ┊ GC (min … max): 0.00% … 83.59%
 Time  (median):     290.875 μs               ┊ GC (median):    0.00%
 Time  (mean ± σ):   300.532 μs ± 127.074 μs  ┊ GC (mean ± σ):  2.83% ±  5.78%

   ▃█▃▃▆▇▆▄▂▆▇▃▁▂▂▁                                              
  ▂█████████████████▆▅▅▄▄▃▃▂▂▂▂▂▁▂▂▁▂▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▃
  284 μs           Histogram: frequency by time          323 μs <

 Memory estimate: 204.62 KiB, allocs estimate: 7174.
BenchmarkTools.Trial: 10000 samples with 921 evaluations.
 Range (min … max):  112.965 ns …  1.595 μs  ┊ GC (min … max): 0.00% … 92.62%
 Time  (median):     115.681 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   116.900 ns ± 34.016 ns  ┊ GC (mean ± σ):  0.71% ±  2.25%

   ▁█▆▇▆    ▃▁▄▅                                                
  ▄██████▃▂▇█████▅▅▄▃▄▃▃▃▂▂▂▂▂▂▂▂▂▂▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▃
  113 ns          Histogram: frequency by time          129 ns <

 Memory estimate: 32 bytes, allocs estimate: 2.
Serializer
BenchmarkTools.Trial: 2963 samples with 1 evaluation.
 Range (min … max):  1.631 ms …   3.924 ms  ┊ GC (min … max): 0.00% … 57.40%
 Time  (median):     1.661 ms               ┊ GC (median):    0.00%
 Time  (mean ± σ):   1.686 ms ± 146.551 μs  ┊ GC (mean ± σ):  0.54% ±  3.65%

    ▆▅█▇▁                                                      
  ▄▇█████▆▅▅▄▅▅▅▄▄▄▃▃▃▂▂▂▃▂▂▂▂▂▂▂▁▂▂▂▂▂▂▂▂▂▂▁▂▁▂▂▁▁▂▂▂▁▂▂▁▁▂▂ ▃
  1.63 ms         Histogram: frequency by time        1.95 ms <

 Memory estimate: 208.92 KiB, allocs estimate: 8211.
BenchmarkTools.Trial: 10000 samples with 451 evaluations.
 Range (min … max):  228.568 ns …   8.422 μs  ┊ GC (min … max):  0.00% … 96.56%
 Time  (median):     240.022 ns               ┊ GC (median):     0.00%
 Time  (mean ± σ):   295.809 ns ± 489.187 ns  ┊ GC (mean ± σ):  16.68% ±  9.63%

  █▂                                                            ▁
  ██▇▆▅▅▄▁▃▃▁▁▁▃▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▄▄ █
  229 ns        Histogram: log(frequency) by time       4.49 μs <

 Memory estimate: 1.05 KiB, allocs estimate: 10.

---
結果: 左から PB Encode， PB Decode， Serializer Encode， Serializer Decode

デコードはいずれもすごく安定している。ほとんどコンスタントタイム。本当か。エンコードはほぼ1桁違う。

   409.264      116.893    4495.16       283.382
  1034.5        117.689    7797.39       285.575
  2160.21       117.172   14348.8        284.722
  4595.56       117.723   27736.4        285.661
  9304.74       117.43    69002.8        286.122
 18879.5        118.238       1.07587e5  289.382
 38578.1        119.432       2.12106e5  289.946
 76448.1        118.169  429743.0        286.454
     1.52358e5  121.127       8.47166e5  287.146
     3.04693e5  119.259       1.68663e6  288.179


------
nakada@garthim pbtest % julia testprocs.jl
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  114.292 μs …  1.760 ms  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     137.833 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   139.271 μs ± 23.223 μs  ┊ GC (mean ± σ):  0.00% ± 0.00%

                     ▃▃ ▃▇▅█▄▃▃▃ ▁                              
  ▁▁▁▁▁▁▁▁▁▁▂▂▂▃▂▃▄▇▆███████████▇█▇▅▅▅▃▃▃▂▂▂▂▁▂▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▃
  114 μs          Histogram: frequency by time          170 μs <

 Memory estimate: 5.75 KiB, allocs estimate: 100.

 MPI

BenchmarkTools.Trial: 4439 samples with 1 evaluation.
 Range (min … max):  578.833 μs …  28.735 ms  ┊ GC (min … max):  0.00% …  0.00%
 Time  (median):     791.125 μs               ┊ GC (median):     0.00%
 Time  (mean ± σ):     1.122 ms ± 937.671 μs  ┊ GC (mean ± σ):  16.53% ± 19.94%

  ▄▇█▇▇▅▄▁              ▁▁ ▁ ▁▁▁▁▁▁ ▁▁▁                         ▂
  ██████████▇██▇▇▇▆██████████████████████▇███▇▇▆▆▅▆▆▆▄▅▅▅▅▅▅▁▄▅ █
  579 μs        Histogram: log(frequency) by time       4.21 ms <

 Memory estimate: 1.75 MiB, allocs estimate: 273.
 

 nakada@garthim pbtest % mpirun -np 2 julia --threads 1 testprocs_mpi.jl
BenchmarkTools.Trial: 4877 samples with 1 evaluation.
 Range (min … max):  569.083 μs …  10.198 ms  ┊ GC (min … max):  0.00% … 47.79%
 Time  (median):     758.333 μs               ┊ GC (median):     0.00%
 Time  (mean ± σ):     1.023 ms ± 682.332 μs  ┊ GC (mean ± σ):  14.23% ± 18.89%

  ▄▆██▇▆▆▅              ▁   ▁▁▁▁        ▁                       ▂
  █████████▆▃▅▃▅▅▅▅▄▆▆▆▇██████████▇█████████▇▇█▇▇▇▇▇▇▆▆▆▅▅▃▆▅▅▆ █
  569 μs        Histogram: log(frequency) by time       3.43 ms <

 Memory estimate: 1.73 MiB, allocs estimate: 273.


 ------
nakada@garthim pbtest % mpirun -np 2 julia --threads 1 mpitest.jl
rank = 1, 1
rank = 0, 1
Rank 1: receive task invoked
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  43.167 μs …  1.285 ms  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     56.584 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   61.925 μs ± 16.514 μs  ┊ GC (mean ± σ):  0.00% ± 0.00%

            ▅█▄▂                                               
  ▂▁▁▁▁▁▁▄▅▇████▇▅▅▄▄▄▃▄▄▄▅▅▄▄▄▄▃▄▃▄▄▃▄▃▃▃▃▃▃▃▃▃▃▃▃▂▂▃▂▂▂▂▂▂▂ ▃
  43.2 μs         Histogram: frequency by time        95.2 μs <

 Memory estimate: 2.63 KiB, allocs estimate: 35.

----
nakada@garthim pbtest % mpirun -np 2 julia --threads 1 mpitest_naive.jl
rank = 1, 1
rank = 0, 1
BenchmarkTools.Trial: 10000 samples with 10 evaluations.
 Range (min … max):  1.179 μs … 89.808 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     1.358 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   1.439 μs ±  1.847 μs  ┊ GC (mean ± σ):  0.00% ± 0.00%

      ▃▅▄▂▂▄▇█▇▅ ▂▁▃▃▃▁                                       
  ▁▂▃▆██████████▇███████▇▆▆▆▅▄▃▃▄▄▃▃▃▃▃▂▃▂▃▂▂▂▂▂▂▂▂▂▂▁▁▁▁▁▁▁ ▄
  1.18 μs        Histogram: frequency by time        1.89 μs <


------------------------
simple RPCのまとめ

構造体をシリアライズして送りつけて、関数テーブルを引いて関数を実行。結果をシリアライズして返す。
サーバ側はread してすぐwrite。クライアント側はチャネル通信のブロックが絡む。

- ローカルホストのTCP通信で1.252ms
- execした場合は 1.143ms
微妙にしかかわらない。

これは何が原因なんだろうか。


----
simple PingPong 

64bit 整数を往復させるだけ。チャネル通信のブロックは行う。

-TCPで 346us

こうしてみると、構造体のシリアライズオーバヘッドはそれなりに大きい?

---- 
## testprocs.jl が異常に早い問題

138usとか。本当にリモートで実行しているのか。なんか最適化で消えてないか。

```
b = @benchmark begin
    f = @spawnat 2 return(1)
    fetch(f)
end
```

下のように書き換えて見たが、結果は変わらない。
```
@everywhere add(a,b) = a + b

##
b = @benchmark begin
    f = @spawnat 2 add(1, 2)
    fetch(f)
end
```

さらに@spawnat 1 とかにすると、14usとかになる。ということは2はリモートでやってるはず。
うーん?

##
Futureの実装が悪いのかもしれない。
Channelで実装したのがまずかったか?


ローカルなFutureを実装してみた。
Thread.Condition を使っている。実装正しいんかこれ。
しかしだめだ、ほとんど変わらない。
うーん。

## Futureをバイパスしてブロッキングでうごくようにしてみた。

送信後ブロッキングで受信するようにしてみた。
なんと! 1.2msのままでまるで変わらん!
ということは、Futureの実装が悪いわけではない。。。

さてはて本当に何なんだ?

flushするようにしてみた。が変わらない。

## Profile
プロファイルを取ってみたがまったくわからん。


## サーバ側のinvoke

invokeが遅い可能性を疑ってバイパスしてみたが
まったく変わらない

## spawnat がなにかずるしているのではないか。
実は呼び出していないのでは、とか疑ったがそんなことはなかった。
サーバ側にカウンタを持たせて呼び出したりしたが普通にインクリメントできている。

いやしかしなんでこんなに速いんだろう。

``` julia
@everywhere begin
    acc = 0
    add(a) = begin 
        global acc
        acc += a; 
        acc 
    end
end

b = @benchmark begin
    f = @spawnat 2 add(1)
    fetch(f)
end
```
## futuremapにデータがたまりまくっているのではないか
と思ってpopするようにしたが、性能に変化なし。

## そもそもどのくらいのオーバヘッドがあるのか

### 直接呼び出し

18.1ns。2GHzだとして36クロック。
``` julia
@benchmark begin
    add(1)
end
```

### @spawnat 1
14 us。
ローカルプロセスだが、1000倍遅い

### @spawnat 2
138 us。
となりのプロセス。10倍遅い。

 

## メッセージのシリアライズコスト
messageをIOBufferに書いて読み出す。

1.0us。帰りも同じコストが掛かるが、それでも2us程度。
うーん。


## naive_pingpong
ただただ単純にpingpongするだけでも322us。これより速いってどうなってるんだ?

simple_pingpong との違いは、手元でFutureを使っているかどうか。
Futureのコストは最大でも30us程度であることがわかる。

### testprocs

MPI_TRANSPORT_ALL だと760us。
TCP_TRANSPORT_ALL だと140us。

TCPは普通にソケット通信しているはずなのに、
異常に速い。どうなってるんだ。


###
cluster.jlを読んでいると、どうも
execのstdoutなどは直接は使っていないのではないか。
普通にSocket を作り直しているように見える。

  cluster.jl でなんか怪しいことをやっている。これはなんだ?
  
    Sockets.nagle(sock, false)
    Sockets.quickack(sock, true)

うーん変わらない。    


###
Serializeを直接呼んでいるわけではなく、
細かく色々やっているっぽい。

Serializeを使わず、構造体の中身を直接書くようにしたら、
ようやく193usになった!
それでもspawnat 2やTCP_TRANSPORT_ALLよりも遅いのか。。
うーん。どんな魔法をつかっているのか。


###
naive でSerializeを使うと335us。
これをInt64のread/writeにすると52us。

かなり速い。
これらはnagleあり。 nagleなしでも52usで変わらず。
このケースでは影響はほとんどない。

- 8バイト 送信 8バイト受信 (1write, 1read)
-   - 52us
- 16バイト 送信 8バイト受信 (2write, 1read)
  - 85us
- 24バイト 送信 8バイト受信 (3write, 1read)
  - 111us
- 32バイト 送信 8バイト受信 (4- write, 1read)
  - 139us
- 32バイト 送信 16バイト受信  (4- write, 2read)
  - 146us 

何をどうやっても、2write 2readは必須なはず。
おそらく問題はreadの側。
libuv を経由しないreadとかありそう?


実効 8Gbps として、1バイト1ns。48バイトに50nsしかかからない。
あれー?


こんなことあるか? どうもreadの回数に比例して時間が
かかっているような気がする。

なんかわからないけどlibuvが妙なことをしているのではないか。


配列を送るようにしたらどうも速い。なるほど。。

messageを送る部分を書き直して、
IOBufferに書き込んだものを送るようにしたら124usになった。
2回readしているのも多分なんか
はしょれそう。unsafe_readとかあるみたいだ。。うーん。

###

myfeatureの同期コストは26us程度
```
using BenchmarkTools
@benchmark begin
    f = MyFuture{Int64}()
    @sync begin
        @async take!(f)
        @async begin
            put!(f, 100)
        end
    end
end
```

### 
mpi_rpc はなんと67us
readがビジーウェイトだから速いぞ!
これでいいのか。。