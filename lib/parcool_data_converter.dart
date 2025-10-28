import 'dart:typed_data';

Uint8List int16ListToUint8List(Int16List int16list) {
  // 1. 分配一个新缓冲区，大小为 Int16List 的两倍
  final Uint8List uint8list = Uint8List(int16list.lengthInBytes);

  // 2. 在新缓冲区上创建 ByteData 视图
  final ByteData byteData = uint8list.buffer.asByteData();

  // 3. 遍历并明确地按 Little Endian 格式写入每一个 16-bit 整数
  for (int i = 0; i < int16list.length; i++) {
    byteData.setInt16(i * 2, int16list[i], Endian.little);
  }

  return uint8list;
}

Int16List uint8ListToInt16List(Uint8List uint8list) {
  // 1. 计算将产生多少个 16-bit 整数
  final int length = uint8list.lengthInBytes ~/ 2;

  // 2. 创建一个新的 Int16List 来存放结果 (这将分配新内存)
  final Int16List int16list = Int16List(length);

  // 3. 创建一个 ByteData 视图来读取原始的 uint8list
  //    asByteData 允许我们在任意偏移量上操作，是安全的
  final ByteData byteData = uint8list.buffer.asByteData(
    uint8list.offsetInBytes,
    uint8list.lengthInBytes,
  );

  // 4. 遍历并手动读取每一个 16-bit 整数
  //    我们明确指定使用 Little Endian (LE)，这
  //    是标准 PCM s16le 格式所要求的。
  for (int i = 0; i < length; i++) {
    int16list[i] = byteData.getInt16(i * 2, Endian.little);
  }

  return int16list;
}