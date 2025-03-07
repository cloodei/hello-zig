pub fn is_sorted(comptime T: type, arr: []T) bool {
    const n = arr.len;
    var i: usize = 1;
    while(i < n) : (i += 1)
        if(arr[i] < arr[i - 1])
            return false;
            
    return true;
}

pub fn is_reverse_sorted(comptime T: type, arr: []T) bool {
    const n = arr.len;
    var i: usize = 1;
    while(i < n) : (i += 1)
        if(arr[i] > arr[i - 1])
            return false;
    
    return true;
}


/// Takes a comparator function with params a, b\
/// Returns unsorted if comparator function returns true, else sorted
pub fn is_sorted_comparator(comptime T: type, arr: []T, cmp: fn(a: T, b: T) bool) bool {
    const n = arr.len;
    var i: usize = 1;
    while(i < n) : (i += 1)
        if(cmp(arr[i], arr[i - 1]))
            return false;
    
    return true;
}

pub fn notContains(comptime T: type, arr: []T, target: T) bool {
    for(arr) |e|
        if(e == target)
            return false;
            
    return true;
}


pub inline fn min(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if(a < b) a else b;
}

pub inline fn max(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if(a > b) a else b;
}

pub inline fn swap(comptime Type: type, a: *Type, b: *Type) void {
    const t = a.*;
    a.* = b.*;
    b.* = t;
}
