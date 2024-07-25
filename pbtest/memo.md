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