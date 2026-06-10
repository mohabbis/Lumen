export async function GET() {
	return new Response('', {
		status: 404,
		headers: {
			'content-type': 'text/plain; charset=utf-8',
		},
	});
}
