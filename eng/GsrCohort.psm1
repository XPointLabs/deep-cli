Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# Pure selectors shared with the established GSR scenario. Values remain in
# memory/private stdin; callers log only roles/counts and closed outcomes.
function Select-GsrGroupHead {
    param($Items,[string]$Name)
    $heads=@($Items|Where-Object {$_.Name -ceq $Name})
    if($heads.Count -ne 1){throw 'One exact named candidate group required; never silently select another group.'}
    return $heads[0]
}

function Select-GsrRetainedConversation {
    param($LeftContacts,$RightContacts)
    $common=@($LeftContacts|Where-Object {$_.conversation -in @($RightContacts|ForEach-Object conversation)})
    if($common.Count -gt 1){throw 'Ambiguous exact pair session.'}
    if($common.Count -eq 0){return $null}
    $left=$common[0];$right=@($RightContacts|Where-Object {$_.conversation -ceq $left.conversation})
    if($right.Count -ne 1 -or $left.conversation -cnotmatch '^[0-9A-Fa-f]{64}$'){throw 'Invalid retained pair session.'}
    if(($left.state -ceq 'PeerAcceptanceRetained' -and $right[0].state -ceq 'LocalAcceptanceRetained') -or
        ($left.state -ceq 'LocalAcceptanceRetained' -and $right[0].state -ceq 'PeerAcceptanceRetained')){return $left.conversation}
    return $null
}

function New-GsrEngineeringPopulation {
    param([ValidateRange(1,4)][int]$Rounds=4,[ValidateRange(0,10000)][int]$Cursor=60)
    # Every planned sample exists before a process/profile is opened. Never
    # construct the denominator from whichever messages happened to succeed.
    foreach($round in 1..$Rounds){foreach($role in 1..3){
        [pscustomobject]@{Round=$round;SenderRole=$role;Sequence=$Cursor+$round;Submitted=$false;CommandOrdinal=0L;Outcome='NotSubmitted'}
    }}
}

function New-DirectEngineeringPopulation {
    param([ValidateRange(1,4)][int]$Rounds=4)
    foreach($round in 1..$Rounds){foreach($sender in 1..3){foreach($recipient in @(1..3|Where-Object {$_ -ne $sender})){
        [pscustomobject]@{Round=$round;SenderRole=$sender;RecipientRole=$recipient;Sequence=$round;Submitted=$false;CommandOrdinal=0L;Outcome='NotSubmitted'}
    }}}
}

Export-ModuleMember -Function Select-GsrGroupHead,Select-GsrRetainedConversation,New-GsrEngineeringPopulation,New-DirectEngineeringPopulation
