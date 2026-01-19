function [finalGood, finalBad, toValidate] = automaticValidation(labelsValidated, labelsWrong, labelsNew, threshold)
	addpath('./aux/')

	% Compute good labels by removing bad labels from the set of all labels
	labelsGood=uint16(unique(labelsValidated));
	labelsGood(labelsGood==0)=[];
	labelsGood(ismember(labelsGood, labelsWrong))=[];

	tic;
	[finalGood, toValidate1] = crossLabels(labelsValidated, labelsGood, labelsNew, threshold);
	toc;

	tic;
	[finalBad , toValidate2] = crossLabels(labelsValidated, labelsWrong, labelsNew, threshold);
	toc;

	tic;
	toValidate=toValidate1+toValidate2;
	toc;
end

function [final, toValidate] = crossLabels(labels, vals, labelsNew, threshold)
	final     =uint16(zeros(size(labels)));
	toValidate=uint16(zeros(size(labels)));

	for i=1:length(vals),
		labels1=labels==vals(i);
		labels2=labelsNew(labels1==1);
		m=uint16(mode(double(labels2)));

		labels2=labelsNew==m;

		eqvals=and(labels1, labels2);
		only1=(labels1-labels2)>0;
		only2=(labels2-labels1)>0;

		common=sum(eqvals(:));
		o1=sum(only1(:));
		o2=sum(only2(:));

		over=common/(common+o1+o2);

		if over<threshold,
			toValidate=toValidate+(uint16(labels1).*vals(i));
		else,
			final=final+(uint16(labels1).*vals(i));
		end
	end
end