% Merge of two channels by only intersecting
function [newImg1, merged] = merge3Dnew(img1, img2)
	labs=uint32(bwlabeln(img1));

	ids=unique(labs(and(img1, img2)));
        
	newImg1=logical(zeros(size(img1)));
	merged =uint32 (zeros(size(img2)));
    inter2=ismember(labs, ids);
    
    merged(inter2)=labs(inter2);
    merged(xor(img2, and(img2, merged)))=1;
    
    newImg1(~inter2)=labs(~inter2);
end
