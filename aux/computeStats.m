function computeStats(img)
	vals=unique(img);
	vals(1)=[];

	[~, ~, ~, auxs, ~, ~, ~, ~, ~] = breakBinaryImage3D(img, false);

	eccen    =cell(length(auxs), 1);
	equivdiam=cell(length(auxs), 1);
	extent   =cell(length(auxs), 1);
	majorAxis=cell(length(auxs), 1);
	minorAxis=cell(length(auxs), 1);
	solidity =cell(length(auxs), 1);

	for i=1:length(auxs),
		imgTmp=auxs{i};

		eccen    {i}=0;
		equivdiam{i}=0;
		extent   {i}=0;
		majorAxis{i}=0;
		minorAxis{i}=0;
		solidity {i}=0;

		for j=1:size(auxs{i}, 3),
			stats=regionprops(imgTmp(:,:,j), 'Eccentricity', 'EquivDiameter', 'Extent', 'MajorAxisLength', 'MinorAxisLength', 'Solidity');

			eccen    {i}=eccen    {i}+stats(1).Eccentricity;
			equivdiam{i}=equivdiam{i}+stats(1).EquivDiameter;
			extent   {i}=extent   {i}+stats(1).Extent;
			majorAxis{i}=majorAxis{i}+stats(1).MajorAxisLength;
			minorAxis{i}=minorAxis{i}+stats(1).MinorAxisLength;
			solidity {i}=solidity {i}+stats(1).Solidity;
		end

		eccen    {i}=eccen    {i}/size(auxs{i}, 3);
		equivdiam{i}=equivdiam{i}/size(auxs{i}, 3);
		extent   {i}=extent   {i}/size(auxs{i}, 3);
		majorAxis{i}=majorAxis{i}/size(auxs{i}, 3);
		minorAxis{i}=minorAxis{i}/size(auxs{i}, 3);
		solidity {i}=solidity {i}/size(auxs{i}, 3);

		fprintf('%d, %f, %f, %f, %f, %f, %f\n', vals(i), eccen{i}, equivdiam{i}, extent{i}, majorAxis{i}, minorAxis{i}, solidity{i});
	end
end
