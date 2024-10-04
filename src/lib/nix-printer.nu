# Literal string
export def s [...args] {
    let args_ = $args | str join " "
    $"\"($args_)\""
}

# Comment
export def c [...args] {
    $args | str join " " | split row "\n" | each {$"# ($in)\n"} | str join ""
}

export def with [imported expr] {
    $"with ($imported); ($expr)"
}

export def inherit [--from (-f)="" n ...names] {
    let names_ = [$n] | append $names | str join " "
    $"inherit (if ($from != "") {$"\(($from))"} else {""}) ($names_);"
}

# Use a record as an attrset
export def rec2a [--rec record={}] {
    mut res = if $rec {"rec {"} else {"{"}
    for elem in ($record | transpose k v) {
        $res = $"($res) ($elem.k) = ($elem.v);"
    }
    $res = $"($res) }"
    $res
}

# attrset
export def a [...args] {
    rec2a ($args | chunks 2 | into record)
}

# list
export def l [...args] {
    mut res = "["
    for elem in $args {
        $res = $"($res) ($elem)"
    }
    $res = $"($res) ]"
    $res
}

export def let_ [defs scope] {
    mut $res = "let"
    for elem in ($defs | chunks 2) {
        $res = $"($res) ($elem.0) = ($elem.1);"
    }
    $res = $"($res) in ($scope)"
    $res
}

# Raw space-separated string concatenation, like for function calls
export def r [...args] {
    $args | str join " "
}

# Same than 'r', but wraps the expression in parentheses
export def p [...args] {
    let args_ = $args | str join " "
    $"\(($args_))"
}

# (Nested) lambda(s)
export def f [...args] {
    mut res = "("
    mut first = true
    for arg in $args {
        let colon = if $first {""} else {": "}
        $res = $"($res)($colon)($arg)"
        $first = false
    }
    $"($res)\)"
}