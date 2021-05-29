<?php

function getData()
{
    $date=date('d-m-Y');
    $header[]='authority: cdn-api.co-vin.in';
    $header[]='sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="90", "Google Chrome";v="90"';
    $header[]='user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36';
    $header[]='origin: https://www.cowin.gov.in';
    $header[]='sec-fetch-site: cross-site';
    $header[]='sec-fetch-mode: cors';
    $header[]='sec-fetch-dest: empty';
    $header[]='referer: https://www.cowin.gov.in/';
    $header[]='accept-language: en-GB,en;q=0.9,hi-IN;q=0.8,hi;q=0.7,en-US;q=0.6';


    $url = "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=650&date=".$date;
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);

    //return the transfer as a string
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    //curl_setopt($ch, CURLOPT_VERBOSE, 1);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $header);
    // $output contains the output string
    $output = curl_exec($ch);

    // close curl resource to free up system resources
    curl_close($ch);     
    return $output;
}

$data = getData();
//$data=file_get_contents("api.json");
file_put_contents("out.json", $data);
$o = json_decode($data);
$c = $o->centers;
echo "Total Center =>".count($c)."\n";
foreach ($c as $v)
{
    
    foreach ($v->sessions as $s)
    {   
        if ($s->min_age_limit == 18 && $s->available_capacity_dose1 > 0 )
          echo $v->name." ".$s->date." -> ".$s->available_capacity_dose1."\n";
    }
    
}

?>
