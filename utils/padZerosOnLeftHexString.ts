export default function (hexString: string, length: number) {
  const padding = '0'.repeat(length - hexString.length)
  return `0x${padding}${hexString.substring(2)}`
}
