<?php
$host = "CUSTOM_IP";
$username = "aws";
$password = "pass";

$conn = mysqli_connect($host,$username,$password);
if ($conn->connect_error){
	die("Connection failed: " . $conn->connect_error);
}
echo "Connect successfully";
?>