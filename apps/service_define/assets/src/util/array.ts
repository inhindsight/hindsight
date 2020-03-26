export const replaceWhere = <T>(predicate: (value: T) => boolean, replacement: T, values: readonly T[]): readonly T[] => {
    return values.map(value => predicate(value) ? replacement : value)
}