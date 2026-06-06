select Ethnicity, {Child's First Name}, Count(*) 
from {usa baby.Popular_Baby_Names} 
where ( Year of Birth >= 2011 ) and ( Year of Birth <= 2019 ) 
group by Ethnicity, histogram({Child's First Name},27)
