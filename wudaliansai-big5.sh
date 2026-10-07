#!/bin/sh
# wudaliansai-big5.sh - 从 wudaliansai 的 live.m3u 中过滤出五大联赛
# 用法: sh wudaliansai-big5.sh [--dump-groups]
#   默认: 抓取 http://localhost:18765/live.m3u,过滤后写入 /www/big5.m3u
#   --dump-groups: 打印所有 group-title,方便调优关键词(不写文件)
#
# 建议 cron (OpenWrt): 每 30 分钟刷新一次
#   */30 * * * * /bin/sh /root/wudaliansai-big5.sh >>/tmp/big5.log 2>&1

SRC="${WUDA_SRC:-http://localhost:18765/live.m3u}"
DST="${WUDA_DST:-/www/big5.m3u}"
TMP_M3U="/tmp/wuda_raw.m3u"
TMP_OUT="/tmp/big5.m3u"

# 五大联赛关键词:联赛名(中/英)+ 2026/27 赛季各队名(中/英/简称)
KW="英超|英格兰超级|Premier League|英格兰足球超级联赛"
KW="$KW|西甲|西班牙甲级|La Liga|LaLiga|西班牙足球甲级联赛"
KW="$KW|德甲|德国甲级|Bundesliga|德国足球甲级联赛"
KW="$KW|意甲|意大利甲级|Serie A|意大利足球甲级联赛"
KW="$KW|法甲|法国甲级|Ligue 1|法国足球甲级联赛"
# 英超 20 队
KW="$KW|阿森纳|Arsenal|曼城|Manchester City|利物浦|Liverpool|切尔西|Chelsea"
KW="$KW|曼联|Manchester United|热刺|Tottenham|纽卡|Newcastle|维拉|Aston Villa"
KW="$KW|埃弗顿|Everton|西汉姆|West Ham|布莱顿|Brighton|狼队|Wolves|Wolverhampton"
KW="$KW|水晶宫|Crystal Palace|富勒姆|Fulham|诺丁汉森林|Nottingham Forest"
KW="$KW|伯恩茅斯|Bournemouth|布伦特福德|Brentford|利兹联|Leeds|伯恩利|Burnley|桑德兰|Sunderland"
# 西甲
KW="$KW|皇马|皇家马德里|Real Madrid|巴萨|巴塞罗那|Barcelona|马竞|马德里竞技|Atletico"
KW="$KW|塞维利亚|Sevilla|贝蒂斯|Real Betis|毕尔巴鄂|Athletic|皇家社会|Real Sociedad"
KW="$KW|比利亚雷亚尔|Villarreal|瓦伦西亚|Valencia|赫塔菲|Getafe|奥萨苏纳|Osasuna"
KW="$KW|塞尔塔|Celta|马略卡|Mallorca|巴列卡诺|Rayo|西班牙人|Espanyol|阿拉维斯|Alaves"
KW="$KW|埃尔切|Elche|莱万特|Levante|奥维耶多|Oviedo"
# 德甲
KW="$KW|拜仁|拜仁慕尼黑|Bayern|多特|多特蒙德|Dortmund|莱比锡|Leipzig|勒沃库森|Leverkusen"
KW="$KW|斯图加特|Stuttgart|门兴|Gladbach|沃尔夫斯堡|Wolfsburg|法兰克福|Frankfurt"
KW="$KW|弗赖堡|Freiburg|霍芬海姆|Hoffenheim|美因茨|Mainz|奥格斯堡|Augsburg"
KW="$KW|不莱梅|云达不莱梅|Werder Bremen|柏林联合|Union Berlin|汉堡|Hamburg|科隆|Koln|Cologne|圣保利|St. Pauli"
# 意甲
KW="$KW|国米|国际米兰|Inter|米兰|AC米兰|Milan|尤文|尤文图斯|Juventus|那不勒斯|Napoli"
KW="$KW|罗马|Roma|拉齐奥|Lazio|亚特兰大|Atalanta|佛罗伦萨|Fiorentina|博洛尼亚|Bologna"
KW="$KW|都灵|Torino|乌迪内斯|Udinese|热那亚|Genoa|卡利亚里|Cagliari|科莫|Como|帕尔马|Parma"
# 法甲
KW="$KW|巴黎|巴黎圣日耳曼|大巴黎|PSG|Paris Saint-Germain|马赛|Marseille|摩纳哥|Monaco"
KW="$KW|里昂|Lyon|里尔|Lille|朗斯|Lens|尼斯|Nice|雷恩|Rennes|南特|Nantes|斯特拉斯堡|Strasbourg"

if [ "$1" = "--dump-groups" ]; then
    curl -s --max-time 30 "$SRC" | grep -o 'group-title="[^"]*"' | sort -u
    exit 0
fi

curl -s --max-time 30 "$SRC" -o "$TMP_M3U" || { echo "$(date): 抓取 live.m3u 失败"; exit 1; }
[ -s "$TMP_M3U" ] || { echo "$(date): live.m3u 为空"; exit 1; }

export KW
awk '
BEGIN { total=0; kept=0 }
/^#EXTM3U/ { next }
/^#EXTINF/ { extinf=$0; total++; next }
/^#/ { extinf=""; next }
NF {
    if (extinf != "") {
        if (extinf ~ ENVIRON["KW"]) { print extinf; print $0; kept++ }
        extinf=""
    }
}
END { printf "total=%d kept=%d\n", total, kept > "/dev/stderr" }
' "$TMP_M3U" > "$TMP_OUT" 2>/tmp/big5.stat

{
    echo "#EXTM3U"
    cat "$TMP_OUT"
} > "${TMP_OUT}.full" && mv "${TMP_OUT}.full" "$DST"

echo "$(date): $(cat /tmp/big5.stat), 输出 $DST"
